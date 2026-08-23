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

RSpec.describe Kitchen::Driver::Aws::InstanceConnect do
  subject(:instance_connect) { described_class.new(config, test_logger) }

  let(:config) { { region: "us-west-2", availability_zone: "us-west-2a" } }
  let(:connect_client) { stub_instance_connect_client }

  before do
    allow(::Aws::EC2InstanceConnect::Client).to receive(:new).and_return(connect_client)
  end

  describe "#initialize" do
    it "builds an Instance Connect client in the configured region" do
      instance_connect
      expect(::Aws::EC2InstanceConnect::Client).to have_received(:new).with(region: "us-west-2")
    end
  end

  describe "#send_ssh_public_key" do
    let(:public_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB kitchen@example" }

    it "pushes the key for the given instance and user" do
      instance_connect.send_ssh_public_key("i-0123456789abcdef0", "ec2-user", public_key)

      expect(request_params_for(connect_client, :send_ssh_public_key)).to eq(
        instance_id: "i-0123456789abcdef0",
        instance_os_user: "ec2-user",
        ssh_public_key: public_key,
        availability_zone: "us-west-2a"
      )
    end

    it "reports which instance and user it is pushing to" do
      instance_connect.send_ssh_public_key("i-0123456789abcdef0", "ec2-user", public_key)

      expect(logged_output.string)
        .to match(/Sending SSH public key to instance i-0123456789abcdef0 for user ec2-user/)
    end

    it "confirms the key was accepted" do
      instance_connect.send_ssh_public_key("i-0123456789abcdef0", "ec2-user", public_key)
      expect(logged_output.string).to match(/SSH public key successfully sent/)
    end

    # The availability zone is optional in the API and the driver does not
    # always know it, so a nil zone has to reach EC2 rather than raise.
    context "with no availability zone configured" do
      let(:config) { { region: "us-west-2" } }

      it "sends the key without a zone" do
        instance_connect.send_ssh_public_key("i-0123456789abcdef0", "ec2-user", public_key)
        expect(request_params_for(connect_client, :send_ssh_public_key)[:availability_zone]).to be_nil
      end
    end

    context "when the key is rejected" do
      before do
        connect_client.stub_responses(:send_ssh_public_key, "AuthException")
      end

      # There is no rescue here: a rejected key means the transport cannot
      # connect, so the error propagates to the caller rather than being logged
      # and swallowed.
      it "lets the error propagate" do
        expect { instance_connect.send_ssh_public_key("i-0123456789abcdef0", "ec2-user", public_key) }
          .to raise_error(::Aws::EC2InstanceConnect::Errors::ServiceError)
      end
    end
  end
end
