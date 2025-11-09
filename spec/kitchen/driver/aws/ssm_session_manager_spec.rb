#
# Author:: GitHub Copilot
#
# Copyright:: 2025, GitHub
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen/driver/aws/ssm_session_manager"

describe Kitchen::Driver::Aws::SsmSessionManager do
  let(:config) do
    {
      region: "us-west-2",
      shared_credentials_profile: nil,
    }
  end
  let(:logger) { instance_double(Logger, debug: nil, info: nil, warn: nil) }
  let(:ssm_client) { instance_double(Aws::SSM::Client) }
  let(:ssm_manager) { described_class.new(config, logger) }

  before do
    allow(Aws::SSM::Client).to receive(:new).and_return(ssm_client)
  end

  describe "#ssm_agent_available?" do
    let(:instance_id) { "i-1234567890abcdef0" }

    context "when SSM agent is online" do
      it "returns true" do
        response = double(
          instance_information_list: [
            double(ping_status: "Online"),
          ]
        )
        expect(ssm_client).to receive(:describe_instance_information)
          .with(filters: [{ key: "InstanceIds", values: [instance_id] }])
          .and_return(response)

        expect(ssm_manager.ssm_agent_available?(instance_id)).to be true
      end
    end

    context "when SSM agent is not online" do
      it "returns false" do
        response = double(
          instance_information_list: [
            double(ping_status: "ConnectionLost"),
          ]
        )
        expect(ssm_client).to receive(:describe_instance_information)
          .with(filters: [{ key: "InstanceIds", values: [instance_id] }])
          .and_return(response)

        expect(ssm_manager.ssm_agent_available?(instance_id)).to be false
      end
    end

    context "when instance not found in SSM" do
      it "returns false" do
        response = double(instance_information_list: [])
        expect(ssm_client).to receive(:describe_instance_information)
          .with(filters: [{ key: "InstanceIds", values: [instance_id] }])
          .and_return(response)

        expect(ssm_manager.ssm_agent_available?(instance_id)).to be false
      end
    end

    context "when SSM API call fails" do
      it "returns false and logs warning" do
        expect(ssm_client).to receive(:describe_instance_information)
          .and_raise(Aws::SSM::Errors::ServiceError.new(nil, "API Error"))

        expect(logger).to receive(:warn).with(/Error checking SSM agent status/)
        expect(ssm_manager.ssm_agent_available?(instance_id)).to be false
      end
    end
  end

  describe "#session_manager_plugin_installed?" do
    context "when plugin is installed" do
      it "returns true" do
        status_double = double(success?: true)
        allow(Open3).to receive(:capture2e).with("session-manager-plugin", "--version").and_return(["1.2.3\n", status_double])

        expect(ssm_manager.session_manager_plugin_installed?).to be true
      end
    end

    context "when plugin is not installed" do
      it "returns false and logs warning" do
        status_double = double(success?: false)
        allow(Open3).to receive(:capture2e).with("session-manager-plugin", "--version").and_return(["", status_double])

        expect(logger).to receive(:warn).with(/Session Manager plugin is not installed/)
        expect(ssm_manager.session_manager_plugin_installed?).to be false
      end
    end
  end
end
