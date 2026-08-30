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
require "tempfile"

RSpec.describe Kitchen::Driver::Aws::InstanceGenerator do
  subject(:generator) { described_class.new(config, aws_client, test_logger) }

  let(:aws_client) { stub_aws_client(client: ec2_client) }
  let(:ec2_client) { stub_ec2_client }
  let(:config) { base_config }
  let(:base_config) { { region: "us-west-2", instance_type: "t3.micro", image_id: "ami-0123456789abcdef0" } }

  # `ec2_instance_data` builds its own EC2 client rather than using the wrapper
  # it was handed, so lookups are intercepted at the constructor.
  before do
    allow(::Aws::EC2::Client).to receive(:new).and_return(ec2_client)
  end

  def instance_data
    generator.ec2_instance_data
  end

  # Every other example here asserts on the Hash `ec2_instance_data` returns,
  # which says nothing about whether EC2 would accept it. A stubbed client
  # validates request parameters against the real EC2 service model, so
  # sending the payload through one is what tells a payload apart from a Hash
  # that merely looks right.
  #
  # This is not hypothetical: the generator spent its life emitting a
  # `licenses` key, which RunInstances has never had. The Hash assertion
  # passed, and every `kitchen create` configuring `licenses` died with
  # "unexpected value at params[:licenses]".
  describe "the payload RunInstances accepts" do
    def run_instances
      ::Aws::EC2::Resource.new(client: ec2_client).create_instances(**instance_data)
    end

    it "is accepted for a plain instance" do
      expect { run_instances }.not_to raise_error
    end

    it "is accepted with licence configurations" do
      config[:licenses] = [{ license_configuration_arn: "arn:aws:license-manager:lic-1" }]

      expect { run_instances }.not_to raise_error
    end

    it "is accepted with a public IP, subnet and security groups" do
      config[:associate_public_ip] = true
      config[:subnet_id] = "subnet-0123456789abcdef0"
      config[:security_group_ids] = ["sg-0123456789abcdef0"]

      expect { run_instances }.not_to raise_error
    end

    it "is accepted with tags, block devices and metadata options" do
      config[:tags] = { "created-by" => "test-kitchen" }
      config[:block_device_mappings] = [{ device_name: "/dev/sda1", ebs: { volume_size: 30 } }]
      config[:metadata_options] = { http_tokens: "required" }

      expect { run_instances }.not_to raise_error
    end

    it "is accepted with placement, tenancy and a shutdown behavior" do
      config[:availability_zone] = "b"
      config[:tenancy] = "host"
      config[:placement] = { host_id: "h-0123456789abcdef0" }
      config[:instance_initiated_shutdown_behavior] = "terminate"

      expect { run_instances }.not_to raise_error
    end
  end

  describe "#ec2_instance_data" do
    it "always requests exactly one instance" do
      expect(instance_data).to include(min_count: 1, max_count: 1)
    end

    it "carries the core instance settings through" do
      expect(instance_data).to include(
        instance_type: "t3.micro",
        image_id: "ami-0123456789abcdef0"
      )
    end

    it "passes the SSH key pair name as key_name" do
      config[:aws_ssh_key_id] = "my-key"
      expect(instance_data[:key_name]).to eq("my-key")
    end

    describe "tags" do
      it "tags both the instance and its volumes" do
        config[:tags] = { "created-by" => "test-kitchen" }

        expect(instance_data[:tag_specifications]).to eq([
          { resource_type: "instance", tags: [{ key: "created-by", value: "test-kitchen" }] },
          { resource_type: "volume", tags: [{ key: "created-by", value: "test-kitchen" }] },
        ])
      end

      # EC2 rejects non-string tag values, so integers and nils are coerced
      # rather than passed through and failing at the API boundary.
      it "stringifies tag values" do
        config[:tags] = { "number" => 42, "nothing" => nil }

        tags = instance_data[:tag_specifications].first[:tags]
        expect(tags).to eq([
          { key: "number", value: "42" },
          { key: "nothing", value: "" },
        ])
      end

      it "omits tag specifications when there are no tags" do
        config[:tags] = {}
        expect(instance_data).not_to have_key(:tag_specifications)
      end
    end

    describe "availability zone" do
      # A bare letter is a convenience shorthand for "this zone in my region".
      it "expands a bare zone letter using the region" do
        config[:availability_zone] = "b"
        expect(instance_data[:placement][:availability_zone]).to eq("us-west-2b")
      end

      it "downcases a fully qualified zone" do
        config[:availability_zone] = "US-WEST-2B"
        expect(instance_data[:placement][:availability_zone]).to eq("us-west-2b")
      end

      it "omits placement when no zone or tenancy is given" do
        expect(instance_data).not_to have_key(:placement)
      end
    end

    describe "tenancy" do
      it "sets tenancy on its own" do
        config[:tenancy] = "dedicated"
        expect(instance_data[:placement]).to eq(tenancy: "dedicated")
      end

      it "merges tenancy alongside an availability zone" do
        config[:availability_zone] = "us-west-2a"
        config[:tenancy] = "host"

        expect(instance_data[:placement]).to eq(
          availability_zone: "us-west-2a", tenancy: "host"
        )
      end
    end

    describe "the placement block" do
      it "passes through each supported placement setting" do
        config[:placement] = {
          affinity: "host",
          availability_zone: "us-west-2c",
          host_id: "h-0123456789abcdef0",
          host_resource_group_arn: "arn:aws:resource-groups:us-west-2:1234:group/hosts",
          partition_number: 2,
          tenancy: "host",
        }

        expect(instance_data[:placement]).to include(
          affinity: "host",
          availability_zone: "us-west-2c",
          host_id: "h-0123456789abcdef0",
          host_resource_group_arn: "arn:aws:resource-groups:us-west-2:1234:group/hosts",
          partition_number: 2,
          tenancy: "host"
        )
      end

      # EC2 accepts a placement group by ID or by name, never both, so each is
      # only forwarded when the other is absent.
      it "sends group_id when only an ID is given" do
        config[:placement] = { group_id: "pg-0123456789abcdef0" }
        expect(instance_data[:placement]).to eq(group_id: "pg-0123456789abcdef0")
      end

      it "sends group_name when only a name is given" do
        config[:placement] = { group_name: "my-group" }
        expect(instance_data[:placement]).to eq(group_name: "my-group")
      end

      it "sends neither when both are given" do
        config[:placement] = { group_id: "pg-0123456789abcdef0", group_name: "my-group" }

        expect(instance_data[:placement]).not_to have_key(:group_id)
        expect(instance_data[:placement]).not_to have_key(:group_name)
      end
    end

    describe "security groups" do
      it "wraps a single security group ID in an array" do
        config[:security_group_ids] = "sg-0123456789abcdef0"
        expect(instance_data[:security_group_ids]).to eq(%w{sg-0123456789abcdef0})
      end

      it "passes a list of security group IDs through" do
        config[:security_group_ids] = %w{sg-aaa sg-bbb}
        expect(instance_data[:security_group_ids]).to eq(%w{sg-aaa sg-bbb})
      end

      it "omits security groups when none are configured" do
        expect(instance_data).not_to have_key(:security_group_ids)
      end
    end

    describe "block device mappings" do
      it "passes mappings through unchanged" do
        mappings = [{ device_name: "/dev/sda1", ebs: { volume_size: 30 } }]
        config[:block_device_mappings] = mappings

        expect(instance_data[:block_device_mappings]).to eq(mappings)
      end

      it "omits the key when the list is empty" do
        config[:block_device_mappings] = []
        expect(instance_data).not_to have_key(:block_device_mappings)
      end

      it "omits the key when the list is nil" do
        config[:block_device_mappings] = nil
        expect(instance_data).not_to have_key(:block_device_mappings)
      end
    end

    describe "other pass-through settings" do
      it "forwards metadata options" do
        config[:metadata_options] = { http_tokens: "required" }
        expect(instance_data[:metadata_options]).to eq(http_tokens: "required")
      end

      it "wraps an IAM profile name in an instance profile" do
        config[:iam_profile_name] = "kitchen-profile"
        expect(instance_data[:iam_instance_profile]).to eq(name: "kitchen-profile")
      end

      # RunInstances calls the parameter `license_specifications`. The payload
      # used to be built under a `licenses` key, which no EC2 API accepts, so
      # configuring `licenses` failed the run outright:
      #
      #   ArgumentError: unexpected value at params[:licenses]
      it "forwards licence configuration ARNs as license_specifications" do
        config[:licenses] = [{ license_configuration_arn: "arn:aws:license-manager:lic-1" }]

        expect(instance_data[:license_specifications]).to eq([
          { license_configuration_arn: "arn:aws:license-manager:lic-1" },
        ])
      end

      it "does not send a licenses parameter, which RunInstances does not accept" do
        config[:licenses] = [{ license_configuration_arn: "arn:aws:license-manager:lic-1" }]

        expect(instance_data).not_to have_key(:licenses)
      end

      it "forwards a shutdown behavior" do
        config[:instance_initiated_shutdown_behavior] = "terminate"
        expect(instance_data[:instance_initiated_shutdown_behavior]).to eq("terminate")
      end

      it "omits an empty shutdown behavior" do
        config[:instance_initiated_shutdown_behavior] = ""
        expect(instance_data).not_to have_key(:instance_initiated_shutdown_behavior)
      end
    end

    # Specifying a network interface moves several top-level settings inside
    # the interface block; EC2 rejects a request that sets them in both places.
    describe "network interfaces" do
      before { config[:associate_public_ip] = true }

      it "declares a single interface at device index 0" do
        expect(instance_data[:network_interfaces]).to eq([
          { device_index: 0, associate_public_ip_address: true, delete_on_termination: true },
        ])
      end

      it "moves the subnet into the interface" do
        config[:subnet_id] = "subnet-0123456789abcdef0"

        expect(instance_data).not_to have_key(:subnet_id)
        expect(instance_data[:network_interfaces][0][:subnet_id]).to eq("subnet-0123456789abcdef0")
      end

      it "moves the private IP address into the interface" do
        config[:private_ip_address] = "10.0.0.5"

        expect(instance_data).not_to have_key(:private_ip_address)
        expect(instance_data[:network_interfaces][0][:private_ip_address]).to eq("10.0.0.5")
      end

      it "moves security groups into the interface as groups" do
        config[:security_group_ids] = %w{sg-aaa}

        expect(instance_data).not_to have_key(:security_group_ids)
        expect(instance_data[:network_interfaces][0][:groups]).to eq(%w{sg-aaa})
      end

      it "requests an IPv6 address when asked" do
        config[:associate_ipv6] = true
        expect(instance_data[:network_interfaces][0][:ipv_6_address_count]).to eq(1)
      end

      it "builds no interface block when associate_public_ip is unset" do
        config.delete(:associate_public_ip)
        expect(instance_data).not_to have_key(:network_interfaces)
      end

      # False is a meaningful value here -- "attach an interface, but no public
      # IP" -- so it must still produce an interface block.
      it "builds an interface block when associate_public_ip is false" do
        config[:associate_public_ip] = false
        expect(instance_data[:network_interfaces][0][:associate_public_ip_address]).to be(false)
      end
    end

    describe "subnet lookup by tag" do
      let(:ec2_client) do
        stub_ec2_client(
          describe_subnets: {
            subnets: [
              { subnet_id: "subnet-small", vpc_id: "vpc-1", available_ip_address_count: 3 },
              { subnet_id: "subnet-roomy", vpc_id: "vpc-1", available_ip_address_count: 250 },
            ],
          }
        )
      end

      before { config[:subnet_filter] = { tag: "Name", value: "kitchen" } }

      # Picking the emptiest subnet spreads instances out and avoids exhausting
      # a subnet that is already nearly full.
      it "chooses the subnet with the most free addresses" do
        expect(instance_data[:subnet_id]).to eq("subnet-roomy")
      end

      it "queries by the configured tag" do
        instance_data

        expect(request_params_for(ec2_client, :describe_subnets)[:filters]).to eq([
          { name: "tag:Name", values: %w{kitchen} },
        ])
      end

      it "accepts several filters at once" do
        config[:subnet_filter] = [{ tag: "Name", value: "kitchen" }, { tag: "Env", value: "test" }]
        instance_data

        expect(request_params_for(ec2_client, :describe_subnets)[:filters]).to eq([
          { name: "tag:Name", values: %w{kitchen} },
          { name: "tag:Env", values: %w{test} },
        ])
      end

      it "writes the chosen subnet back into the config" do
        instance_data
        expect(config[:subnet_id]).to eq("subnet-roomy")
      end

      context "when no subnet matches" do
        let(:ec2_client) { stub_ec2_client(describe_subnets: { subnets: [] }) }

        it "raises rather than launching into an unknown subnet" do
          expect { instance_data }.to raise_error(/Subnets with tags .* not found/)
        end
      end

      context "when an explicit subnet ID is also set" do
        it "leaves the explicit subnet alone" do
          config[:subnet_id] = "subnet-explicit"

          expect(instance_data[:subnet_id]).to eq("subnet-explicit")
          expect(requests_for(ec2_client, :describe_subnets)).to be_empty
        end
      end
    end

    describe "security group lookup by filter" do
      let(:ec2_client) do
        stub_ec2_client(
          describe_subnets: { subnets: [{ subnet_id: "subnet-1", vpc_id: "vpc-1" }] },
          describe_security_groups: { security_groups: [{ group_id: "sg-found" }] }
        )
      end

      before { config[:subnet_id] = "subnet-1" }

      it "finds a group by name within the subnet's VPC" do
        config[:security_group_filter] = { name: "kitchen-sg" }

        expect(instance_data[:security_group_ids]).to eq(%w{sg-found})
        expect(request_params_for(ec2_client, :describe_security_groups)[:filters]).to eq([
          { name: "group-name", values: %w{kitchen-sg} },
          { name: "vpc-id", values: %w{vpc-1} },
        ])
      end

      it "finds a group by tag within the subnet's VPC" do
        config[:security_group_filter] = { tag: "Name", value: "kitchen-sg" }
        instance_data

        expect(request_params_for(ec2_client, :describe_security_groups)[:filters]).to eq([
          { name: "tag:Name", values: %w{kitchen-sg} },
          { name: "vpc-id", values: %w{vpc-1} },
        ])
      end

      it "collects groups from several filters" do
        config[:security_group_filter] = [{ name: "sg-a" }, { name: "sg-b" }]
        expect(instance_data[:security_group_ids]).to eq(%w{sg-found sg-found})
      end

      # The tag branch used to overwrite the filter list the name branch had
      # just built, so a filter carrying both silently searched on the tag
      # alone and could attach a group the name ruled out.
      it "requires both a name and a tag when a filter gives both" do
        config[:security_group_filter] = { name: "kitchen-sg", tag: "Role", value: "web" }
        instance_data

        expect(request_params_for(ec2_client, :describe_security_groups)[:filters]).to eq([
          { name: "group-name", values: %w{kitchen-sg} },
          { name: "tag:Role", values: %w{web} },
          { name: "vpc-id", values: %w{vpc-1} },
        ])
      end

      # A filter naming neither left the request with no filters at all, and
      # describe_security_groups with no filters returns every security group
      # in the region -- all of which were then attached to the instance.
      it "raises rather than searching on nothing when a filter names neither" do
        config[:security_group_filter] = { group_name: "kitchen-sg" }

        expect { instance_data }.to raise_error(/needs a `name` or a `tag`/)
      end

      it "does not send an unfiltered request when a filter names neither" do
        config[:security_group_filter] = { group_name: "kitchen-sg" }

        expect { instance_data }.to raise_error(/needs a `name` or a `tag`/)
        expect(requests_for(ec2_client, :describe_security_groups)).to be_empty
      end

      context "when a filter matches nothing" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_subnets: { subnets: [{ subnet_id: "subnet-1", vpc_id: "vpc-1" }] },
            describe_security_groups: { security_groups: [] }
          )
        end

        it "raises naming the filter that failed" do
          config[:security_group_filter] = { name: "missing-sg" }

          expect { instance_data }
            .to raise_error(/A Security Group matching the following filter could not be found/)
        end
      end

      context "when explicit security group IDs are set" do
        it "skips the lookup entirely" do
          config[:security_group_ids] = %w{sg-explicit}
          config[:security_group_filter] = { name: "kitchen-sg" }

          expect(instance_data[:security_group_ids]).to eq(%w{sg-explicit})
          expect(requests_for(ec2_client, :describe_security_groups)).to be_empty
        end
      end

      # The VPC used to be read off `describe_subnets(subnet_ids: [nil])`, so a
      # filter with no subnet alongside it -- the natural configuration in a
      # default VPC account -- died on `undefined method 'vpc_id' for nil`
      # before anything was launched.
      context "when no subnet is configured" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_vpcs: { vpcs: [{ vpc_id: "vpc-default" }] },
            describe_security_groups: { security_groups: [{ group_id: "sg-found" }] }
          )
        end

        before { config.delete(:subnet_id) }

        it "searches the default VPC" do
          config[:security_group_filter] = { name: "kitchen-sg" }

          expect(instance_data[:security_group_ids]).to eq(%w{sg-found})
          expect(request_params_for(ec2_client, :describe_security_groups)[:filters]).to eq([
            { name: "group-name", values: %w{kitchen-sg} },
            { name: "vpc-id", values: %w{vpc-default} },
          ])
        end

        it "asks for the default VPC rather than describing a nil subnet" do
          config[:security_group_filter] = { name: "kitchen-sg" }
          instance_data

          expect(requests_for(ec2_client, :describe_subnets)).to be_empty
          expect(request_params_for(ec2_client, :describe_vpcs)[:filters]).to eq([
            { name: "isDefault", values: %w{true} },
          ])
        end

        # EC2-Classic, or an account whose default VPC has been deleted. The
        # name still narrows the search, so this is not the unfiltered request
        # that would attach every group in the region.
        context "and the account has no default VPC" do
          let(:ec2_client) do
            stub_ec2_client(
              describe_vpcs: { vpcs: [] },
              describe_security_groups: { security_groups: [{ group_id: "sg-found" }] }
            )
          end

          it "searches on the name alone" do
            config[:security_group_filter] = { name: "kitchen-sg" }

            expect(instance_data[:security_group_ids]).to eq(%w{sg-found})
            expect(request_params_for(ec2_client, :describe_security_groups)[:filters]).to eq([
              { name: "group-name", values: %w{kitchen-sg} },
            ])
          end
        end
      end

      # Same nil dereference, reached the other way: a subnet that was named
      # but does not exist.
      context "when the configured subnet does not exist" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_subnets: { subnets: [] },
            describe_security_groups: { security_groups: [{ group_id: "sg-found" }] }
          )
        end

        it "raises naming the subnet" do
          config[:security_group_filter] = { name: "kitchen-sg" }

          expect { instance_data }
            .to raise_error(/Subnet subnet-1 not found while resolving security_group_filter/)
        end
      end
    end
  end

  describe "#prepared_user_data" do
    it "is nil when no user data is configured" do
      expect(generator.prepared_user_data).to be_nil
    end

    it "base64 encodes an inline script" do
      config[:user_data] = "#!/bin/sh\necho hello\n"

      expect(Base64.decode64(generator.prepared_user_data)).to eq("#!/bin/sh\necho hello\n")
    end

    it "reads user data from a file path" do
      Tempfile.create("user-data") do |file|
        file.write("#!/bin/sh\nfrom-a-file\n")
        file.flush
        config[:user_data] = file.path

        expect(Base64.decode64(generator.prepared_user_data)).to eq("#!/bin/sh\nfrom-a-file\n")
      end
    end

    # A script containing a null byte would make File.file? raise, so the null
    # check has to come first. It also reliably identifies inline content.
    it "treats content containing a null byte as inline data" do
      config[:user_data] = "binary\0content"

      expect(Base64.decode64(generator.prepared_user_data)).to eq("binary\0content")
    end

    it "reads the file only once" do
      config[:user_data] = "inline"
      first = generator.prepared_user_data

      config[:user_data] = "changed"
      expect(generator.prepared_user_data).to equal(first)
    end

    it "is included in the instance data when set" do
      config[:user_data] = "inline"
      expect(instance_data[:user_data]).to eq(Base64.encode64("inline"))
    end

    it "is absent from the instance data when unset" do
      expect(instance_data).not_to have_key(:user_data)
    end
  end
end
