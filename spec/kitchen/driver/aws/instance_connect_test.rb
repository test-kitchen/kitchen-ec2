#
# Author:: Alex Kokkinos
#
# Copyright:: 2025, Alex Kokkinos
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use t his file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen/driver/aws/instance_connect"

describe Kitchen::Driver::Aws::InstanceConnect do
  let(:config) do
    {
      region: "us-east-1",
      availability_zone: "us-east-1a"
    }
  end
  
  let(:logger) { instance_double("Logger") }
  let(:aws_client) { instance_double("Aws::EC2InstanceConnect::Client") }
  
  let(:instance_connect) { described_class.new(config, logger) }
  
  before do
    allow(::Aws::EC2InstanceConnect::Client).to receive(:new).and_return(aws_client)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
  end

  describe "#initialize" do
    it "sets config and logger instance variables" do
      expect(instance_connect.instance_variable_get(:@config)).to eq(config)
      expect(instance_connect.instance_variable_get(:@logger)).to eq(logger)
    end

    it "creates AWS EC2InstanceConnect client with correct region" do
      expect(::Aws::EC2InstanceConnect::Client).to have_received(:new)
        .with(region: "us-east-1")
    end
  end

  describe "#send_ssh_public_key" do
    let(:instance_id) { "i-1234567890abcdef0" }
    let(:username) { "ec2-user" }
    let(:public_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..." }

    before do
      allow(aws_client).to receive(:send_ssh_public_key)
    end

    it "logs info message with instance details" do
      expect(logger).to receive(:info)
        .with("Sending SSH public key to instance #{instance_id} for user #{username}")
      
      instance_connect.send_ssh_public_key(instance_id, username, public_key)
    end

    it "calls AWS client with correct parameters" do
      expected_params = {
        instance_id: instance_id,
        instance_os_user: username,
        ssh_public_key: public_key,
        availability_zone: "us-east-1a"
      }

      expect(aws_client).to receive(:send_ssh_public_key).with(expected_params)
      
      instance_connect.send_ssh_public_key(instance_id, username, public_key)
    end

    it "logs debug message on successful completion" do
      expect(logger).to receive(:debug)
        .with("SSH public key successfully sent to instance")
      
      instance_connect.send_ssh_public_key(instance_id, username, public_key)
    end

    it "completes the full workflow" do
      expect(logger).to receive(:info).ordered
      expect(aws_client).to receive(:send_ssh_public_key).ordered
      expect(logger).to receive(:debug).ordered
      
      instance_connect.send_ssh_public_key(instance_id, username, public_key)
    end
  end
end
