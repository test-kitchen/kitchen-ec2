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

require "kitchen/driver/ec2"

RSpec.describe Kitchen::Driver::Aws::SsmSessionManager do
  subject(:session_manager) { described_class.new(config, test_logger) }

  let(:config) { { region: "us-west-2", shared_credentials_profile: "kitchen" } }
  let(:ssm_client) { stub_ssm_client }

  before do
    allow(::Aws::SSM::Client).to receive(:new).and_return(ssm_client)
  end

  describe "#initialize" do
    it "builds an SSM client for the configured region and profile" do
      session_manager
      expect(::Aws::SSM::Client).to have_received(:new).with(region: "us-west-2", profile: "kitchen")
    end
  end

  describe "#ssm_agent_available?" do
    def stub_ping_status(status)
      ssm_client.stub_responses(
        :describe_instance_information,
        instance_information_list: [{ instance_id: "i-0123456789abcdef0", ping_status: status }]
      )
    end

    it "is true when the agent is online" do
      stub_ping_status("Online")
      expect(session_manager.ssm_agent_available?("i-0123456789abcdef0")).to be(true)
    end

    # A registered but unreachable instance still appears in the list, so the
    # ping status -- not the presence of a record -- is what decides.
    it "is false when the agent is registered but not online" do
      stub_ping_status("ConnectionLost")
      expect(session_manager.ssm_agent_available?("i-0123456789abcdef0")).to be(false)
    end

    it "is false when the instance is not registered with SSM at all" do
      ssm_client.stub_responses(:describe_instance_information, instance_information_list: [])
      expect(session_manager.ssm_agent_available?("i-0123456789abcdef0")).to be(false)
    end

    it "asks about the one instance it was given" do
      stub_ping_status("Online")
      session_manager.ssm_agent_available?("i-0123456789abcdef0")

      expect(request_params_for(ssm_client, :describe_instance_information)[:filters]).to eq([
        { key: "InstanceIds", values: %w{i-0123456789abcdef0} },
      ])
    end

    it "reports availability" do
      stub_ping_status("Online")
      session_manager.ssm_agent_available?("i-0123456789abcdef0")
      expect(logged_output.string).to match(/SSM agent is available on instance i-0123456789abcdef0/)
    end

    it "warns when the agent is unavailable" do
      stub_ping_status("ConnectionLost")
      session_manager.ssm_agent_available?("i-0123456789abcdef0")
      expect(logged_output.string).to match(/SSM agent is not available/)
    end

    # This method is polled in a retry loop while an instance boots, so an API
    # error has to read as "not ready yet" rather than abort the run.
    context "when SSM returns an error" do
      before { ssm_client.stub_responses(:describe_instance_information, "InvalidInstanceId") }

      it "is false rather than raising" do
        expect(session_manager.ssm_agent_available?("i-0123456789abcdef0")).to be(false)
      end

      it "warns with the underlying message" do
        session_manager.ssm_agent_available?("i-0123456789abcdef0")
        expect(logged_output.string).to match(/Error checking SSM agent status/)
      end
    end
  end

  describe "#session_manager_plugin_installed?" do
    def stub_plugin_check(success:, output: "")
      status = instance_double(Process::Status, success?: success)
      allow(Open3).to receive(:capture2e).with("session-manager-plugin", "--version").and_return([output, status])
    end

    it "is true when the plugin responds to --version" do
      stub_plugin_check(success: true, output: "1.2.553.0")
      expect(session_manager.session_manager_plugin_installed?).to be(true)
    end

    it "is false when the plugin exits non-zero" do
      stub_plugin_check(success: false)
      expect(session_manager.session_manager_plugin_installed?).to be(false)
    end

    it "points at the install instructions when the plugin is missing" do
      stub_plugin_check(success: false)
      session_manager.session_manager_plugin_installed?
      expect(logged_output.string).to match(/session-manager-working-with-install-plugin/)
    end

    # A missing binary raises Errno::ENOENT out of Open3 rather than returning
    # an unsuccessful status, so this rescue -- not the exit-code branch above
    # -- is what actually runs on a machine without the plugin installed.
    #
    # This only works because the rescue names `::StandardError`. Unqualified,
    # it would resolve to Kitchen::StandardError and let Errno::ENOENT escape.
    context "when the plugin binary is not installed" do
      before do
        allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT, "session-manager-plugin")
      end

      it "is false rather than raising" do
        expect(session_manager.session_manager_plugin_installed?).to be(false)
      end

      it "warns with the underlying message" do
        session_manager.session_manager_plugin_installed?
        expect(logged_output.string).to match(/Error checking for session-manager-plugin/)
      end
    end

    context "when the check fails with an error Kitchen owns" do
      before do
        allow(Open3).to receive(:capture2e).and_raise(Kitchen::StandardError, "kitchen exploded")
      end

      it "is false rather than raising" do
        expect(session_manager.session_manager_plugin_installed?).to be(false)
      end

      it "warns with the underlying message" do
        session_manager.session_manager_plugin_installed?
        expect(logged_output.string).to match(/Error checking for session-manager-plugin: kitchen exploded/)
      end
    end
  end
end
