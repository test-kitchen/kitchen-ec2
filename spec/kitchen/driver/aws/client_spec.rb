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

RSpec.describe Kitchen::Driver::Aws::Client do
  subject(:wrapper) { described_class.new("us-west-2") }

  describe "#initialize" do
    # The wrapper does not hold connection settings itself -- it pushes them
    # into the SDK's process-wide config and lets the SDK build clients from
    # that. Every example here therefore asserts on `Aws.config`.
    it "applies the region to the SDK configuration" do
      described_class.new("eu-central-1")
      expect(::Aws.config[:region]).to eq("eu-central-1")
    end

    it "defaults to the default shared credentials profile" do
      described_class.new("us-west-2")
      expect(::Aws.config[:profile]).to eq("default")
    end

    it "applies an explicit profile" do
      described_class.new("us-west-2", "kitchen")
      expect(::Aws.config[:profile]).to eq("kitchen")
    end

    it "applies an HTTP proxy" do
      described_class.new("us-west-2", "default", "http://proxy.example.com:8080")
      expect(::Aws.config[:http_proxy]).to eq("http://proxy.example.com:8080")
    end

    it "enables peer verification by default" do
      described_class.new("us-west-2")
      expect(::Aws.config[:ssl_verify_peer]).to be(true)
    end

    it "applies an explicit ssl_verify_peer setting" do
      described_class.new("us-west-2", "default", nil, nil, false)
      expect(::Aws.config[:ssl_verify_peer]).to be(false)
    end

    it "applies a retry limit when one is given" do
      described_class.new("us-west-2", "default", nil, 7)
      expect(::Aws.config[:retry_limit]).to eq(7)
    end

    # A nil retry limit must not overwrite the SDK's own default, so it is
    # omitted from the config update rather than written as nil.
    it "leaves the SDK's retry limit alone when none is given" do
      ::Aws.config.delete(:retry_limit)
      described_class.new("us-west-2", "default", nil, nil)
      expect(::Aws.config).not_to have_key(:retry_limit)
    end
  end

  describe "#client" do
    it "returns an EC2 client" do
      expect(wrapper.client).to be_an(::Aws::EC2::Client)
    end

    it "memoizes the client" do
      expect(wrapper.client).to equal(wrapper.client)
    end
  end

  describe "#resource" do
    it "returns an EC2 resource" do
      expect(wrapper.resource).to be_an(::Aws::EC2::Resource)
    end

    it "memoizes the resource" do
      expect(wrapper.resource).to equal(wrapper.resource)
    end
  end

  describe "#create_instance" do
    let(:ec2_client) do
      stub_ec2_client(run_instances: { instances: [{ instance_id: "i-0123456789abcdef0" }] })
    end

    before { allow(wrapper).to receive(:resource).and_return(::Aws::EC2::Resource.new(client: ec2_client)) }

    it "returns the first created instance" do
      instance = wrapper.create_instance(image_id: "ami-123", min_count: 1, max_count: 1)
      expect(instance.id).to eq("i-0123456789abcdef0")
    end

    it "passes the instance options straight through to EC2" do
      wrapper.create_instance(image_id: "ami-123", min_count: 1, max_count: 1, instance_type: "t3.micro")

      expect(request_params_for(ec2_client, :run_instances)).to include(
        image_id: "ami-123", instance_type: "t3.micro"
      )
    end
  end

  describe "#get_instance" do
    let(:ec2_client) { stub_ec2_client }

    before { allow(wrapper).to receive(:resource).and_return(::Aws::EC2::Resource.new(client: ec2_client)) }

    it "returns an instance resource for the given ID" do
      expect(wrapper.get_instance("i-0123456789abcdef0").id).to eq("i-0123456789abcdef0")
    end
  end

  describe "#get_instance_from_spot_request" do
    let(:ec2_client) do
      stub_ec2_client(
        describe_instances: {
          reservations: [{ instances: [{ instance_id: "i-0123456789abcdef0" }] }],
        }
      )
    end

    before { allow(wrapper).to receive(:resource).and_return(::Aws::EC2::Resource.new(client: ec2_client)) }

    it "returns the instance fulfilling the spot request" do
      expect(wrapper.get_instance_from_spot_request("sir-abc123").id).to eq("i-0123456789abcdef0")
    end

    it "filters on the spot instance request ID" do
      wrapper.get_instance_from_spot_request("sir-abc123")

      expect(request_params_for(ec2_client, :describe_instances)[:filters]).to eq([
        { name: "spot-instance-request-id", values: %w{sir-abc123} },
      ])
    end

    context "when no instance has been fulfilled yet" do
      let(:ec2_client) { stub_ec2_client(describe_instances: { reservations: [] }) }

      it "returns nil" do
        expect(wrapper.get_instance_from_spot_request("sir-abc123")).to be_nil
      end
    end
  end

  describe "#instance_exists?" do
    let(:ec2_client) do
      stub_ec2_client(
        describe_instances: {
          reservations: [{ instances: [{ instance_id: "i-0123456789abcdef0" }] }],
        }
      )
    end

    before { allow(wrapper).to receive(:resource).and_return(::Aws::EC2::Resource.new(client: ec2_client)) }

    it "is true when EC2 knows the instance" do
      expect(wrapper.instance_exists?("i-0123456789abcdef0")).to be(true)
    end

    context "when EC2 does not know the instance" do
      let(:ec2_client) do
        client = stub_ec2_client
        client.stub_responses(:describe_instances, "InvalidInstanceID.NotFound")
        client
      end

      it "is false" do
        expect(wrapper.instance_exists?("i-0123456789abcdef0")).to be(false)
      end
    end
  end
end
