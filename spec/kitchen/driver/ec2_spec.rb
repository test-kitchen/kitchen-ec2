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
require "fileutils"
require "tmpdir"

RSpec.describe Kitchen::Driver::Ec2 do
  subject(:driver) { build_driver(**config) }

  let(:config) { { image_id: "ami-0123456789abcdef0" } }
  let(:state) { {} }

  let(:image_name) { "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801" }
  let(:image) { build_image(name: image_name) }
  let(:ec2_client) { stub_ec2_client(describe_images: { images: [image.data.to_h] }) }
  let(:aws_client) { stub_aws_client(client: ec2_client) }

  before { allow(driver).to receive(:ec2).and_return(aws_client) }

  # Several config validations end the process with `exit!`, which cannot be
  # rescued. Stubbing it to raise SystemExit keeps the "stop here" semantics
  # while letting an example assert that it happened.
  def stub_exit!(target = driver)
    allow(target).to receive(:exit!).and_raise(SystemExit)
  end

  # Run a config through validation and return whatever it wrote to stderr.
  #
  # The validation lambdas are defined in the class body, so their `self` is
  # the driver *class* -- both `warn` and `exit!` are called on it rather than
  # on the instance being validated. That is why `exit!` is stubbed on
  # described_class here and on the instance elsewhere, and why the warnings
  # land on stderr instead of in the Test Kitchen logger.
  def validate(**config)
    allow(described_class).to receive(:exit!).and_raise(SystemExit)
    captured = StringIO.new
    original = $stderr
    $stderr = captured

    begin
      build_driver(**config).finalize_config!(build_instance_double)
      [:ok, captured.string]
    rescue SystemExit
      [:exited, captured.string]
    ensure
      $stderr = original
    end
  end

  describe "plugin metadata" do
    it "declares driver API version 2" do
      expect(driver.diagnose_plugin[:api_version]).to eq(2)
    end

    it "reports the gem version as the plugin version" do
      expect(driver.diagnose_plugin[:version]).to eq(Kitchen::Driver::EC2_VERSION)
    end
  end

  describe "default configuration" do
    # Built directly rather than through the factory, which injects a region
    # of its own. spec_helper clears AWS_REGION, so this is the true default.
    it "defaults the region to us-east-1" do
      expect(described_class.new({})[:region]).to eq("us-east-1")
    end

    it "tags instances as created by test-kitchen" do
      expect(driver[:tags]).to eq("created-by" => "test-kitchen")
    end

    it "defaults tenancy to default" do
      expect(driver[:tenancy]).to eq("default")
    end

    it "defaults the SSH key type to rsa" do
      expect(driver[:aws_ssh_key_type]).to eq("rsa")
    end

    it "verifies SSL peers by default" do
      expect(driver[:ssl_verify_peer]).to be(true)
    end

    it "does not use Instance Connect or SSM by default" do
      expect(driver[:use_instance_connect]).to be(false)
      expect(driver[:use_ssm_session_manager]).to be(false)
    end

    it "has no user data on a Linux platform" do
      expect(driver[:user_data]).to be_nil
    end
  end

  describe "config validations" do
    # These keys moved elsewhere in the config across past major versions.
    # Leaving them set would silently change how an instance is built, so the
    # driver refuses to run rather than ignoring them.
    {
      ebs_volume_size: "block_device_mappings",
      ebs_delete_on_termination: "block_device_mappings",
      ebs_device_name: "block_device_mappings",
      ssh_key: "transport.ssh_key",
      ssh_timeout: "transport.connection_timeout",
      ssh_retries: "transport.connection_retries",
      username: "transport.username",
      flavor_id: "instance_type",
    }.each do |old_key, new_key|
      it "refuses to run when the removed key #{old_key} is set" do
        outcome, stderr = validate(old_key => "anything")

        expect(outcome).to eq(:exited)
        expect(stderr).to include(new_key)
      end
    end

    # Credentials in kitchen.yml end up committed to version control, so the
    # driver refuses them outright and directs users at the standard AWS chain.
    %i{aws_access_key_id aws_secret_access_key aws_session_token}.each do |key|
      it "refuses to run when #{key} is set in the config" do
        outcome, stderr = validate(key => "secret")

        expect(outcome).to eq(:exited)
        expect(stderr).to match(/no longer a valid config option/)
      end
    end

    it "accepts each valid tenancy" do
      %w{default host dedicated}.each do |tenancy|
        expect(validate(tenancy: tenancy).first).to eq(:ok)
      end
    end

    it "rejects an unknown tenancy" do
      outcome, stderr = validate(tenancy: "shared")

      expect(outcome).to eq(:exited)
      expect(stderr).to match(/invalid value for option 'tenancy'/)
    end

    it "accepts the valid shutdown behaviors" do
      [nil, "stop", "terminate"].each do |behavior|
        expect(validate(instance_initiated_shutdown_behavior: behavior).first).to eq(:ok)
      end
    end

    it "rejects an unknown shutdown behavior" do
      outcome, stderr = validate(instance_initiated_shutdown_behavior: "hibernate")

      expect(outcome).to eq(:exited)
      expect(stderr).to match(/Valid values are 'stop' or 'terminate'/)
    end

    # YAML makes it easy to write tags as a list of one-key hashes, which then
    # fails deep inside the tagging call. Catching it here gives a usable error.
    it "rejects tags written as an array" do
      outcome, stderr = validate(tags: [{ foo: "bar" }])

      expect(outcome).to eq(:exited)
      expect(stderr).to match(/must be specified as a single hash/)
    end

    it "accepts tags written as a hash" do
      expect(validate(tags: { "foo" => "bar" }).first).to eq(:ok)
    end

    # Both features rewrite the transport's connection handling, so enabling
    # both would leave whichever ran last silently in charge.
    it "refuses to enable Instance Connect and SSM Session Manager together" do
      outcome, stderr = validate(use_instance_connect: true, use_ssm_session_manager: true)

      expect(outcome).to eq(:exited)
      expect(stderr).to match(/Cannot use both/)
    end

    it "accepts Instance Connect on its own" do
      expect(validate(use_instance_connect: true).first).to eq(:ok)
    end

    it "accepts SSM Session Manager on its own" do
      expect(validate(use_ssm_session_manager: true).first).to eq(:ok)
    end
  end

  describe "#image" do
    it "looks the configured image up in EC2" do
      expect(driver.image.name).to eq(image_name)
    end

    it "memoizes the lookup" do
      driver.image
      driver.image

      expect(requests_for(ec2_client, :describe_images).size).to eq(1)
    end

    context "with no image_id and no image_search" do
      # `default_ami` normally fills image_id in, so reaching here means the
      # platform name was not recognized and no search was configured either.
      it "raises explaining that one or the other is required" do
        driver = build_driver
        allow(driver).to receive_messages(ec2: aws_client, config: { image_id: nil })

        expect { driver.image }
          .to raise_error(/Neither image_id nor an image_search specified/)
      end
    end
  end

  describe "#default_instance_type" do
    it "uses t3.micro for a modern HVM image" do
      expect(driver.default_instance_type).to eq("t3.micro")
    end

    context "with a paravirtual image" do
      let(:image) { build_image(name: image_name, virtualization_type: "paravirtual") }

      # t3 instances require HVM, so a paravirtual image has to fall back to the
      # older t1 family.
      it "falls back to t1.micro" do
        expect(driver.default_instance_type).to eq("t1.micro")
      end

      it "explains why it picked the older family" do
        driver.default_instance_type
        expect(logged_output.string).to match(/image is paravirtual/)
      end
    end
  end

  describe "#actual_platform" do
    it "detects the platform from the image that was actually chosen" do
      expect(driver.actual_platform).to be_an_instance_of(Kitchen::Driver::Aws::StandardPlatform::Ubuntu)
    end

    context "with an image no platform recognizes" do
      let(:image) { build_image(name: "some-private-golden-image") }

      it "is nil" do
        expect(driver.actual_platform).to be_nil
      end
    end
  end

  describe "#desired_platform" do
    it "builds a platform from the Test Kitchen platform name" do
      driver = build_driver(instance_attributes: { platform: Kitchen::Platform.new(name: "debian-12") })
      allow(driver).to receive(:ec2).and_return(aws_client)

      expect(driver.desired_platform.name).to eq("debian")
      expect(driver.desired_platform.version).to eq("12")
    end

    it "is nil for a platform name the driver does not know" do
      driver = build_driver(instance_attributes: { platform: Kitchen::Platform.new(name: "plan9-4") })
      allow(driver).to receive(:ec2).and_return(aws_client)

      expect(driver.desired_platform).to be_nil
    end
  end

  describe "#default_ami" do
    it "searches for an image matching the requested platform" do
      driver = build_driver(instance_attributes: { platform: Kitchen::Platform.new(name: "ubuntu-24.04") })
      allow(driver).to receive(:ec2).and_return(aws_client)

      expect(driver.default_ami).to eq(image.id)
    end

    # Falling back to Ubuntu keeps `kitchen create` working for a suite whose
    # platform name the driver does not recognize.
    it "falls back to searching for Ubuntu for an unknown platform" do
      driver = build_driver(instance_attributes: { platform: Kitchen::Platform.new(name: "plan9-4") })
      allow(driver).to receive(:ec2).and_return(aws_client)

      driver.default_ami

      filters = request_params_for(ec2_client, :describe_images)[:filters]
      expect(filters).to include(name: "owner-id", values: %w{099720109477})
    end

    it "prefers an explicit image_search over the platform's own filters" do
      driver = build_driver(image_search: { "name" => "my-custom-image-*" })
      allow(driver).to receive(:ec2).and_return(aws_client)

      driver.default_ami

      expect(request_params_for(ec2_client, :describe_images)[:filters])
        .to eq([{ name: "name", values: %w{my-custom-image-*} }])
    end
  end

  describe "#update_username" do
    it "records the platform's default username in the state" do
      driver.update_username(state)
      expect(state[:username]).to eq("ubuntu")
    end

    # A username the user set explicitly must win over the detected default.
    # The check compares against the transport class's own default, so any
    # value the transport does not itself default to counts as explicit.
    it "leaves an explicitly configured username alone" do
      transport = Kitchen::Transport::Dummy.new(username: "deploy")
      driver = build_driver(instance_attributes: { transport: transport })
      allow(driver).to receive(:ec2).and_return(aws_client)

      driver.update_username(state)

      expect(state).not_to have_key(:username)
    end

    context "with an image no platform recognizes" do
      let(:image) { build_image(name: "some-private-golden-image") }

      it "leaves the username unset" do
        driver.update_username(state)
        expect(state).not_to have_key(:username)
      end
    end
  end

  describe "#hostname" do
    let(:server) do
      instance_double(
        ::Aws::EC2::Instance,
        public_dns_name: "ec2-1-2-3-4.compute.amazonaws.com",
        public_ip_address: "1.2.3.4",
        private_ip_address: "10.0.0.5",
        private_dns_name: "ip-10-0-0-5.internal",
        id: "i-0123456789abcdef0"
      )
    end

    {
      "dns" => "ec2-1-2-3-4.compute.amazonaws.com",
      "public" => "1.2.3.4",
      "private" => "10.0.0.5",
      "private_dns" => "ip-10-0-0-5.internal",
      "id" => "i-0123456789abcdef0",
    }.each do |interface, expected|
      it "returns the #{interface} address when asked for it" do
        expect(driver.hostname(server, interface)).to eq(expected)
      end
    end

    it "raises a user error for an unknown interface type" do
      expect { driver.hostname(server, "carrier-pigeon") }
        .to raise_error(Kitchen::UserError, /Invalid interface/)
    end

    # With no interface requested, the ordered mapping is walked and the first
    # populated value wins -- public DNS ahead of public IP, and so on.
    it "prefers public DNS when no interface is requested" do
      expect(driver.hostname(server)).to eq("ec2-1-2-3-4.compute.amazonaws.com")
    end

    it "skips empty values when falling through the ordered mapping" do
      allow(server).to receive_messages(public_dns_name: "", public_ip_address: "1.2.3.4")
      expect(driver.hostname(server)).to eq("1.2.3.4")
    end
  end

  describe "#sudo_command" do
    it "returns the provisioner's sudo command when sudo is enabled" do
      provisioner = Kitchen::Provisioner::Dummy.new(sudo: true, sudo_command: "sudo -E")
      driver = build_driver(instance_attributes: { provisioner: provisioner })

      expect(driver.sudo_command).to eq("sudo -E")
    end

    it "returns an empty string when sudo is disabled" do
      provisioner = Kitchen::Provisioner::Dummy.new(sudo: false)
      driver = build_driver(instance_attributes: { provisioner: provisioner })

      expect(driver.sudo_command).to eq("")
    end
  end

  describe "#image_info" do
    it "summarizes the attributes that drove the image choice" do
      summary = driver.image_info(image)

      expect(summary).to include("Architecture: x86_64")
      expect(summary).to include("Virtualization: hvm")
      expect(summary).to include("Storage: ebs gp3")
    end

    it "omits the volume type when the root device has no EBS block" do
      bare = build_image(name: image_name, block_device_mappings: [])
      expect(driver.image_info(bare)).to include("Storage: ebs,")
    end
  end

  describe "#expand_config" do
    it "expands an array value into one config per element" do
      expanded = driver.expand_config({ instance_type: %w{t3.micro t3.small} }, :instance_type)

      expect(expanded.map { |c| c[:instance_type] }).to eq(%w{t3.micro t3.small})
    end

    it "leaves a scalar value as a single config" do
      expanded = driver.expand_config({ instance_type: "t3.micro" }, :instance_type)
      expect(expanded).to eq([{ instance_type: "t3.micro" }])
    end

    it "does not mutate the config it was given" do
      original = { instance_type: %w{t3.micro t3.small} }
      driver.expand_config(original, :instance_type)

      expect(original[:instance_type]).to eq(%w{t3.micro t3.small})
    end
  end

  describe "#with_request_limit_backoff" do
    it "returns the block's value when nothing goes wrong" do
      expect(driver.with_request_limit_backoff(state) { :done }).to eq(:done)
    end

    it "retries when EC2 reports the request limit was exceeded" do
      allow(driver).to receive(:sleep)
      attempts = 0

      result = driver.with_request_limit_backoff(state) do
        attempts += 1
        raise ::Aws::EC2::Errors::RequestLimitExceeded.new(nil, "Request limit exceeded") if attempts < 3

        :done
      end

      expect(result).to eq(:done)
      expect(attempts).to eq(3)
    end

    it "gives up after five retries" do
      allow(driver).to receive(:sleep)

      expect do
        driver.with_request_limit_backoff(state) do
          raise ::Aws::EC2::Errors::RequestLimitExceeded.new(nil, "Request limit exceeded")
        end
      end.to raise_error(::Aws::EC2::Errors::RequestLimitExceeded)
    end

    # Only throttling is retried. Any other failure is a real error and must
    # surface immediately rather than being retried five times first.
    it "does not retry an unrelated error" do
      attempts = 0

      expect do
        driver.with_request_limit_backoff(state) do
          attempts += 1
          raise ::Aws::EC2::Errors::InvalidInstanceIDNotFound.new(nil, "nope")
        end
      end.to raise_error(::Aws::EC2::Errors::InvalidInstanceIDNotFound)

      expect(attempts).to eq(1)
    end
  end

  describe "#submit_server" do
    let(:generator) { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
    let(:server) { instance_double(::Aws::EC2::Instance, id: "i-0123456789abcdef0") }

    before do
      allow(driver).to receive(:instance_generator).and_return(generator)
      allow(generator).to receive(:ec2_instance_data).and_return(instance_type: "t3.micro")
      allow(aws_client).to receive(:create_instance).and_return(server)
    end

    it "creates the instance from the generated payload" do
      expect(driver.submit_server).to eq(server)
      expect(aws_client).to have_received(:create_instance).with(instance_type: "t3.micro")
    end

    it "logs the payload it is about to send" do
      driver.submit_server
      expect(logged_output.string).to match(/instance_type = "t3.micro"/)
    end
  end

  describe "#submit_spot" do
    let(:generator) { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
    let(:server) { instance_double(::Aws::EC2::Instance, id: "i-0123456789abcdef0") }
    let(:config) { { image_id: "ami-0123456789abcdef0", spot_price: "0.05" } }

    before do
      allow(driver).to receive(:instance_generator).and_return(generator)
      allow(generator).to receive(:ec2_instance_data).and_return({})
      allow(aws_client).to receive(:create_instance).and_return(server)
    end

    def market_options
      driver.submit_spot
      expect(aws_client).to have_received(:create_instance) do |data|
        @market_options = data[:instance_market_options]
      end
      @market_options
    end

    it "requests a spot instance at the configured maximum price" do
      expect(market_options).to eq(market_type: "spot", spot_options: { max_price: "0.05" })
    end

    # "ondemand" means "take a spot instance but do not cap the price", which
    # EC2 expresses as a spot request with no max_price at all.
    %w{ondemand on-demand}.each do |value|
      it "omits the maximum price for a spot_price of #{value}" do
        driver = build_driver(image_id: "ami-0123456789abcdef0", spot_price: value)
        allow(driver).to receive_messages(ec2: aws_client, instance_generator: generator)
        driver.submit_spot

        expect(aws_client).to have_received(:create_instance) do |data|
          expect(data[:instance_market_options][:spot_options]).to eq({})
        end
      end
    end

    it "passes a block duration through when configured" do
      driver = build_driver(image_id: "ami-0123456789abcdef0", spot_price: "0.05", block_duration_minutes: 60)
      allow(driver).to receive_messages(ec2: aws_client, instance_generator: generator)
      driver.submit_spot

      expect(aws_client).to have_received(:create_instance) do |data|
        expect(data[:instance_market_options][:spot_options][:block_duration_minutes]).to eq(60)
      end
    end
  end

  describe "#submit_spots" do
    let(:generator) { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
    let(:server) { instance_double(::Aws::EC2::Instance, id: "i-0123456789abcdef0") }

    before do
      allow(driver).to receive(:instance_generator).and_return(generator)
      allow(generator).to receive(:ec2_instance_data).and_return({})
    end

    # A spot request can fail because one instance type or one subnet has no
    # capacity, so the driver tries each combination before giving up.
    context "with several instance types" do
      let(:config) do
        {
          image_id: "ami-0123456789abcdef0",
          spot_price: "0.05",
          instance_type: %w{t3.micro t3.small},
          subnet_id: "subnet-0123456789abcdef0",
        }
      end

      it "returns the first type that can be fulfilled" do
        attempts = []
        allow(aws_client).to receive(:create_instance) do
          attempts << driver.config[:instance_type]
          raise "no capacity" if attempts.size == 1

          server
        end

        expect(driver.submit_spots).to eq(server)
        expect(attempts).to eq(%w{t3.micro t3.small})
      end

      it "raises listing every failure when none can be fulfilled" do
        allow(aws_client).to receive(:create_instance).and_raise("no capacity")

        expect { driver.submit_spots }
          .to raise_error(/Could not create a spot instance:.*no capacity/m)
      end
    end

    context "with a subnet filter" do
      let(:config) do
        {
          image_id: "ami-0123456789abcdef0",
          spot_price: "0.05",
          instance_type: "t3.micro",
          subnet_filter: { tag: "Name", value: "kitchen" },
        }
      end

      let(:ec2_client) do
        stub_ec2_client(
          describe_images: { images: [image.data.to_h] },
          describe_subnets: {
            subnets: [
              { subnet_id: "subnet-a", vpc_id: "vpc-1" },
              { subnet_id: "subnet-b", vpc_id: "vpc-1" },
            ],
          }
        )
      end

      before { allow(::Aws::EC2::Client).to receive(:new).and_return(ec2_client) }

      it "tries each matching subnet in turn" do
        attempts = []
        allow(aws_client).to receive(:create_instance) do
          attempts << driver.config[:subnet_id]
          raise "no capacity" if attempts.size == 1

          server
        end

        expect(driver.submit_spots).to eq(server)
        expect(attempts).to eq(%w{subnet-a subnet-b})
      end

      context "when the filter matches no subnets" do
        let(:ec2_client) do
          stub_ec2_client(describe_images: { images: [image.data.to_h] }, describe_subnets: { subnets: [] })
        end

        it "raises rather than falling back to an arbitrary subnet" do
          expect { driver.submit_spots }.to raise_error(/Subnets with tags .* not found/)
        end
      end
    end
  end

  describe "#create_security_group" do
    let(:ec2_client) do
      stub_ec2_client(
        describe_images: { images: [image.data.to_h] },
        describe_vpcs: { vpcs: [{ vpc_id: "vpc-default" }] },
        describe_subnets: { subnets: [{ subnet_id: "subnet-1", vpc_id: "vpc-from-subnet" }] },
        create_security_group: { group_id: "sg-created" }
      )
    end

    it "records the new group in the state" do
      driver.create_security_group(state)
      expect(state[:auto_security_group_id]).to eq("sg-created")
    end

    it "tags the group as created by test-kitchen" do
      driver.create_security_group(state)

      expect(request_params_for(ec2_client, :create_security_group)[:tag_specifications]).to eq([
        {
          resource_type: "security-group",
          tags: [{ key: "created-by", value: "test-kitchen" }],
        },
      ])
    end

    it "names the group with a random suffix so parallel runs do not collide" do
      driver.create_security_group(state)

      expect(request_params_for(ec2_client, :create_security_group)[:group_name])
        .to match(/\Akitchen-[a-z0-9]{8}\z/)
    end

    # SSH, RDP and both WinRM ports, so the same group works for every platform
    # the driver supports.
    it "opens SSH, RDP and WinRM" do
      driver.create_security_group(state)

      permissions = request_params_for(ec2_client, :authorize_security_group_ingress)[:ip_permissions]
      expect(permissions.map { |p| p[:from_port] }).to eq([22, 3389, 5985, 5986])
      expect(permissions.map { |p| p[:ip_protocol] }.uniq).to eq(%w{tcp})
    end

    it "opens the ports to the whole internet by default" do
      driver.create_security_group(state)

      permissions = request_params_for(ec2_client, :authorize_security_group_ingress)[:ip_permissions]
      expect(permissions.first[:ip_ranges]).to eq([{ cidr_ip: "0.0.0.0/0" }])
    end

    it "honours a list of allowed CIDR ranges" do
      driver = build_driver(image_id: "ami-1", security_group_cidr_ip: %w{10.0.0.0/8 192.168.0.0/16})
      allow(driver).to receive(:ec2).and_return(aws_client)
      driver.create_security_group(state)

      permissions = request_params_for(ec2_client, :authorize_security_group_ingress)[:ip_permissions]
      expect(permissions.first[:ip_ranges]).to eq([
        { cidr_ip: "10.0.0.0/8" },
        { cidr_ip: "192.168.0.0/16" },
      ])
    end

    it "creates the group in the subnet's VPC when a subnet is configured" do
      driver = build_driver(image_id: "ami-1", subnet_id: "subnet-1")
      allow(driver).to receive(:ec2).and_return(aws_client)
      driver.create_security_group(state)

      expect(request_params_for(ec2_client, :create_security_group)[:vpc_id]).to eq("vpc-from-subnet")
    end

    it "falls back to the account's default VPC" do
      driver.create_security_group(state)
      expect(request_params_for(ec2_client, :create_security_group)[:vpc_id]).to eq("vpc-default")
    end

    context "with no default VPC" do
      let(:ec2_client) do
        stub_ec2_client(
          describe_images: { images: [image.data.to_h] },
          describe_vpcs: { vpcs: [] },
          create_security_group: { group_id: "sg-created" }
        )
      end

      # An account with no default VPC is assumed to be EC2-Classic, where a
      # security group is not scoped to a VPC at all.
      it "creates the group without a VPC" do
        driver.create_security_group(state)
        expect(request_params_for(ec2_client, :create_security_group)).not_to have_key(:vpc_id)
      end
    end

    it "does nothing when a group has already been created" do
      state[:auto_security_group_id] = "sg-existing"
      driver.create_security_group(state)

      expect(requests_for(ec2_client, :create_security_group)).to be_empty
    end
  end

  describe "#delete_security_group" do
    let(:ec2_client) { stub_ec2_client(describe_images: { images: [image.data.to_h] }) }

    it "deletes the group and clears it from the state" do
      state[:auto_security_group_id] = "sg-created"
      driver.delete_security_group(state)

      expect(request_params_for(ec2_client, :delete_security_group)[:group_id]).to eq("sg-created")
      expect(state).not_to have_key(:auto_security_group_id)
    end

    # Only groups the driver created itself are removed; a user-supplied group
    # is never touched.
    it "does nothing when no group was auto-created" do
      driver.delete_security_group(state)
      expect(requests_for(ec2_client, :delete_security_group)).to be_empty
    end
  end

  describe "#create_key" do
    let(:kitchen_root) { Dir.mktmpdir }
    let(:key_path) { File.join(kitchen_root, ".kitchen", "default-ubuntu.pem") }
    let(:config) { { image_id: "ami-1", kitchen_root: kitchen_root } }
    let(:ec2_client) do
      stub_ec2_client(
        describe_images: { images: [image.data.to_h] },
        create_key_pair: { key_name: "kitchen-generated", key_material: "PRIVATE KEY MATERIAL" }
      )
    end

    before { FileUtils.mkdir_p(File.join(kitchen_root, ".kitchen")) }
    after { FileUtils.remove_entry(kitchen_root) }

    it "records the key name in the state" do
      driver.create_key(state)
      expect(state[:auto_key_id]).to eq("kitchen-generated")
    end

    it "writes the private key where the transport can find it" do
      driver.create_key(state)

      expect(state[:ssh_key]).to eq(key_path)
      expect(File.read(key_path)).to eq("PRIVATE KEY MATERIAL")
    end

    # SSH refuses to use a key that other users can read.
    it "writes the key readable only by its owner" do
      driver.create_key(state)
      expect(File.stat(key_path).mode & 0o777).to eq(0o600)
    end

    it "uses the configured key type" do
      driver = build_driver(image_id: "ami-1", kitchen_root: kitchen_root, aws_ssh_key_type: "ed25519")
      allow(driver).to receive(:ec2).and_return(aws_client)
      driver.create_key(state)

      expect(request_params_for(ec2_client, :create_key_pair)[:key_type]).to eq("ed25519")
    end

    it "tags the key pair as created by test-kitchen" do
      driver.create_key(state)

      expect(request_params_for(ec2_client, :create_key_pair)[:tag_specifications]).to eq([
        { resource_type: "key-pair", tags: [{ key: "created-by", value: "test-kitchen" }] },
      ])
    end

    it "does nothing when a key has already been created" do
      state[:auto_key_id] = "kitchen-existing"
      driver.create_key(state)

      expect(requests_for(ec2_client, :create_key_pair)).to be_empty
    end
  end

  describe "#delete_key" do
    let(:kitchen_root) { Dir.mktmpdir }
    let(:key_path) { File.join(kitchen_root, ".kitchen", "default-ubuntu.pem") }
    let(:config) { { image_id: "ami-1", kitchen_root: kitchen_root } }

    before do
      FileUtils.mkdir_p(File.join(kitchen_root, ".kitchen"))
      File.write(key_path, "PRIVATE KEY MATERIAL")
    end

    after { FileUtils.remove_entry(kitchen_root) }

    it "deletes the key pair, the local file and the state entry" do
      state[:auto_key_id] = "kitchen-generated"
      driver.delete_key(state)

      expect(request_params_for(ec2_client, :delete_key_pair)[:key_name]).to eq("kitchen-generated")
      expect(File).not_to exist(key_path)
      expect(state).not_to have_key(:auto_key_id)
    end

    it "does nothing when no key was auto-created" do
      driver.delete_key(state)

      expect(requests_for(ec2_client, :delete_key_pair)).to be_empty
      expect(File).to exist(key_path)
    end
  end

  describe "#attach_network_interface" do
    let(:config) do
      { image_id: "ami-1", elastic_network_interface_id: "eni-0123456789abcdef0" }
    end
    let(:ec2_client) do
      stub_ec2_client(
        describe_images: { images: [image.data.to_h] },
        describe_network_interface_attribute: { attachment: nil }
      )
    end

    before do
      allow(::Aws::EC2::Client).to receive(:new).and_return(ec2_client)
      state[:server_id] = "i-0123456789abcdef0"
    end

    it "attaches a free interface at device index 1" do
      driver.attach_network_interface(state)

      expect(request_params_for(ec2_client, :attach_network_interface)).to eq(
        device_index: 1,
        instance_id: "i-0123456789abcdef0",
        network_interface_id: "eni-0123456789abcdef0"
      )
    end

    context "when the interface is already attached elsewhere" do
      let(:ec2_client) do
        stub_ec2_client(
          describe_images: { images: [image.data.to_h] },
          describe_network_interface_attribute: {
            attachment: { attachment_id: "eni-attach-1", instance_id: "i-other" },
          }
        )
      end

      # `Kitchen::Driver::Base` overrides `puts` to route through the Test
      # Kitchen logger, so this notice lands in the log rather than on stdout.
      it "leaves it alone" do
        driver.attach_network_interface(state)

        expect(logged_output.string).to match(/already attached/)
        expect(requests_for(ec2_client, :attach_network_interface)).to be_empty
      end
    end

    context "when the interface does not exist" do
      before do
        ec2_client.stub_responses(
          :describe_network_interface_attribute,
          ::Aws::EC2::Errors::InvalidNetworkInterfaceIDNotFound.new(nil, "no such network interface")
        )
      end

      # A missing ENI is reported but does not abort the run, since the instance
      # itself is already up by this point.
      it "warns instead of raising" do
        expect { driver.attach_network_interface(state) }.not_to raise_error
        expect(logged_output.string).to match(/no such network interface/)
      end
    end
  end

  describe "#destroy" do
    let(:server) { instance_double(::Aws::EC2::Instance, id: "i-0123456789abcdef0") }

    before do
      allow(aws_client).to receive_messages(get_instance: server, instance_exists?: false)
      allow(server).to receive(:terminate)
    end

    it "terminates the instance and clears it from the state" do
      state[:server_id] = "i-0123456789abcdef0"
      driver.destroy(state)

      expect(server).to have_received(:terminate)
      expect(state).not_to have_key(:server_id)
      expect(state).not_to have_key(:hostname)
    end

    # `kitchen destroy` is run to clean up after a failed create, so an instance
    # that is already gone is a success, not an error.
    it "ignores an instance that has already been terminated" do
      state[:server_id] = "i-0123456789abcdef0"
      allow(server).to receive(:terminate)
        .and_raise(::Aws::EC2::Errors::InvalidInstanceIDNotFound.new(nil, "gone"))

      expect { driver.destroy(state) }.not_to raise_error
      expect(logged_output.string).to match(/probably already destroyed/)
    end

    it "does nothing when there is no instance to destroy" do
      driver.destroy(state)
      expect(server).not_to have_received(:terminate)
    end

    # An auto-created security group cannot be deleted while an instance is
    # still using it, so termination has to complete first.
    it "waits for termination before removing an auto-created security group" do
      state[:server_id] = "i-0123456789abcdef0"
      state[:auto_security_group_id] = "sg-created"
      allow(aws_client).to receive(:instance_exists?).and_return(true)
      allow(server).to receive(:wait_until_terminated)

      driver.destroy(state)

      expect(server).to have_received(:wait_until_terminated)
      expect(request_params_for(ec2_client, :delete_security_group)[:group_id]).to eq("sg-created")
    end

    context "with dedicated hosts" do
      let(:config) { { image_id: "ami-1", tenancy: "host", deallocate_dedicated_host: true } }

      it "releases hosts it manages that have no instances left" do
        allow(driver).to receive_messages(
          hosts_with_capacity: [instance_double(::Aws::EC2::Types::Host, host_id: "h-empty")],
          host_unused?: true
        )
        allow(driver).to receive(:deallocate_host)

        driver.destroy(state)

        expect(driver).to have_received(:deallocate_host).with("h-empty")
      end

      it "leaves hosts alone when deallocation is not enabled" do
        driver = build_driver(image_id: "ami-1", tenancy: "host", deallocate_dedicated_host: false)
        allow(driver).to receive(:ec2).and_return(aws_client)
        allow(driver).to receive(:deallocate_host)

        driver.destroy(state)

        expect(driver).not_to have_received(:deallocate_host)
      end
    end
  end

  describe "#create_ec2_json" do
    subject(:driver) { build_driver(instance_attributes: { provisioner: provisioner }, **config) }

    let(:connection) { instance_double(Kitchen::Transport::Dummy::Connection) }
    # sudo is set explicitly: a detached Dummy provisioner cannot resolve its
    # own :sudo default, which reads back through the instance it lacks.
    let(:provisioner) { Kitchen::Provisioner::Dummy.new(sudo: true, sudo_command: "sudo") }

    before do
      allow(driver.instance.transport).to receive(:connection).and_return(connection)
      allow(connection).to receive(:execute)
    end

    it "writes the ohai hint with sudo on a Unix platform" do
      driver.create_ec2_json(state)

      expect(connection).to have_received(:execute).with(%r{touch /etc/chef/ohai/hints/ec2\.json})
    end

    context "on Windows" do
      subject(:driver) do
        build_driver(
          instance_attributes: { platform: Kitchen::Platform.new(name: "windows-2022"), provisioner: provisioner },
          **config
        )
      end

      it "writes the ohai hint with PowerShell" do
        driver.create_ec2_json(state)

        expect(connection).to have_received(:execute).with(/New-Item -Force C:\\chef\\ohai\\hints\\ec2\.json/)
      end
    end
  end

  describe "#default_windows_user_data" do
    subject(:driver) do
      build_driver(instance_attributes: { platform: Kitchen::Platform.new(name: "windows-2022"), transport: transport }, **config)
    end

    let(:transport) { Kitchen::Transport::Dummy.new }

    it "wraps the script in a powershell block so EC2 executes it" do
      expect(driver.default_windows_user_data).to start_with("<powershell>")
      expect(driver.default_windows_user_data).to end_with("</powershell>\n")
    end

    it "enables PS remoting and opens the WinRM firewall port" do
      script = driver.default_windows_user_data

      expect(script).to include("Enable-PSRemoting")
      expect(script).to include("localport=5985")
    end

    # EC2Launch (2016+) and the older EC2Config service log to different paths,
    # so the script picks one at runtime.
    it "chooses a log path based on the detected OS version" do
      script = driver.default_windows_user_data

      expect(script).to include('C:\ProgramData\Amazon\EC2-Windows\Launch\Log\kitchen-ec2.log')
      expect(script).to include('C:\Program Files\Amazon\Ec2ConfigService\Logs\kitchen-ec2.log')
    end

    it "creates no extra account for the built-in administrator" do
      transport = Kitchen::Transport::Dummy.new(username: "Administrator", password: "hunter2")
      driver = build_driver(
        instance_attributes: { platform: Kitchen::Platform.new(name: "windows-2022"), transport: transport },
        **config
      )

      expect(driver.default_windows_user_data).not_to include("net.exe user")
    end

    context "with a custom administrator account" do
      let(:transport) { Kitchen::Transport::Dummy.new(username: "kitchen", password: "hunter2") }

      it "creates the account and adds it to Administrators" do
        script = driver.default_windows_user_data

        expect(script).to include('$username="kitchen"')
        expect(script).to include('$password="hunter2"')
        expect(script).to include("net.exe localgroup Administrators /add $username")
      end

      # A generated password will not necessarily satisfy the default policy,
      # so complexity is relaxed before the account is created.
      it "relaxes the password complexity policy first" do
        expect(driver.default_windows_user_data).to include("PasswordComplexity")
      end
    end
  end

  describe "#finalize_config!" do
    def transport_for(**config)
      transport = Kitchen::Transport::Dummy.new
      build_driver_with_instance(transport: transport, image_id: "ami-1", **config)
      transport
    end

    it "leaves the transport alone by default" do
      expect(transport_for).not_to respond_to(:instance_connect_override_applied)
    end

    it "overrides the transport when Instance Connect is enabled" do
      expect(transport_for(use_instance_connect: true)).to respond_to(:instance_connect_override_applied)
    end

    it "overrides the transport when SSM Session Manager is enabled" do
      expect(transport_for(use_ssm_session_manager: true)).to respond_to(:ssm_session_manager_override_applied)
    end

    # The override wraps the transport's `connection` method, so applying it
    # twice would wrap the wrapper and push the SSH key more than once.
    it "does not override the transport twice" do
      transport = Kitchen::Transport::Dummy.new
      driver = build_driver_with_instance(transport: transport, image_id: "ami-1", use_instance_connect: true)
      original = transport.method(:connection)

      driver.finalize_config!(driver.instance)

      expect(transport.method(:connection)).to eq(original)
    end

    describe "InSpec verifier overrides" do
      # The verifier override only makes sense for InSpec, which builds its own
      # SSH options rather than going through the transport.
      it "is not applied to a non-InSpec verifier" do
        verifier = Kitchen::Verifier::Dummy.new
        build_driver_with_instance(verifier: verifier, image_id: "ami-1", use_instance_connect: true)

        expect(verifier).not_to respond_to(:instance_connect_inspec_override_applied)
      end

      it "is applied to the InSpec verifier" do
        verifier = Kitchen::Verifier::Dummy.new
        allow(verifier).to receive(:name).and_return("Inspec")
        build_driver_with_instance(verifier: verifier, image_id: "ami-1", use_instance_connect: true)

        expect(verifier).to respond_to(:instance_connect_inspec_override_applied)
      end
    end
  end

  describe "Instance Connect" do
    let(:config) { { image_id: "ami-1", use_instance_connect: true } }

    before { state[:server_id] = "i-0123456789abcdef0" }

    describe "the SSH proxy command" do
      def proxy_command(**overrides)
        driver = build_driver(image_id: "ami-1", use_instance_connect: true, **overrides)
        allow(driver).to receive(:ec2).and_return(aws_client)
        driver.send(:instance_connect_configure_ssh_proxy_command, state)
        state[:ssh_proxy_command]
      end

      it "opens a tunnel to the instance in the configured region" do
        expect(proxy_command).to eq(
          "aws ec2-instance-connect open-tunnel --instance-id i-0123456789abcdef0 " \
          "--max-tunnel-duration 3600 --region us-west-2"
        )
      end

      it "targets a specific endpoint when one is configured" do
        expect(proxy_command(instance_connect_endpoint_id: "eice-123"))
          .to include("--instance-connect-endpoint-id eice-123")
      end

      it "passes the shared credentials profile through" do
        expect(proxy_command(shared_credentials_profile: "kitchen")).to include("--profile kitchen")
      end

      it "records the connection details for the transport" do
        driver.send(:instance_connect_configure_ssh_proxy_command, state)

        expect(state[:instance_connect_config]).to include(
          server_id: "i-0123456789abcdef0",
          region: "us-west-2",
          tunnel_mode: true
        )
      end
    end

    describe "endpoint availability" do
      # An explicitly configured endpoint is taken at face value, saving a
      # describe call on every connection.
      it "is true without a lookup when an endpoint ID is configured" do
        driver = build_driver(image_id: "ami-1", instance_connect_endpoint_id: "eice-123")
        allow(driver).to receive(:ec2).and_return(aws_client)

        expect(driver.send(:instance_connect_endpoint_available?, state)).to be(true)
        expect(requests_for(ec2_client, :describe_instance_connect_endpoints)).to be_empty
      end

      context "with an endpoint in the instance's VPC" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_images: { images: [image.data.to_h] },
            describe_instances: { reservations: [{ instances: [{ vpc_id: "vpc-1" }] }] },
            describe_instance_connect_endpoints: {
              instance_connect_endpoints: [{ instance_connect_endpoint_id: "eice-found" }],
            }
          )
        end

        it "is true" do
          expect(driver.send(:instance_connect_endpoint_available?, state)).to be(true)
        end

        it "looks only for completed endpoints in that VPC" do
          driver.send(:instance_connect_endpoint_available?, state)

          expect(request_params_for(ec2_client, :describe_instance_connect_endpoints)[:filters]).to eq([
            { name: "vpc-id", values: %w{vpc-1} },
            { name: "state", values: %w{create-complete} },
          ])
        end
      end

      context "with no endpoint in the instance's VPC" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_images: { images: [image.data.to_h] },
            describe_instances: { reservations: [{ instances: [{ vpc_id: "vpc-1" }] }] },
            describe_instance_connect_endpoints: { instance_connect_endpoints: [] }
          )
        end

        it "is false, so the driver falls back to direct SSH" do
          expect(driver.send(:instance_connect_endpoint_available?, state)).to be(false)
        end
      end

      it "is false when the instance's VPC cannot be determined" do
        expect(driver.send(:instance_connect_endpoint_available?, {})).to be(false)
      end

      # Instance Connect endpoints are not available in every region or to
      # every IAM principal, so a rejection means "no endpoint", not "abort".
      context "when the account may not describe endpoints" do
        let(:ec2_client) do
          stub_ec2_client(
            describe_images: { images: [image.data.to_h] },
            describe_instances: { reservations: [{ instances: [{ vpc_id: "vpc-1" }] }] }
          )
        end

        before do
          ec2_client.stub_responses(:describe_instance_connect_endpoints, "UnauthorizedOperation")
        end

        it "is false rather than raising" do
          expect(driver.send(:instance_connect_endpoint_available?, state)).to be(false)
        end
      end
    end

    describe "direct SSH configuration" do
      let(:server) do
        instance_double(::Aws::EC2::Instance, public_dns_name: "ec2-1-2-3-4.compute.amazonaws.com")
      end

      before { allow(aws_client).to receive(:get_instance).and_return(server) }

      it "points the hostname at the instance's public DNS name" do
        driver.send(:instance_connect_configure_direct_ssh, state)
        expect(state[:hostname]).to eq("ec2-1-2-3-4.compute.amazonaws.com")
      end

      it "records the connection details for the transport" do
        driver.send(:instance_connect_configure_direct_ssh, state)

        expect(state[:instance_connect_config]).to include(
          direct_ssh: true,
          hostname: "ec2-1-2-3-4.compute.amazonaws.com"
        )
      end

      context "when the instance has no public DNS name" do
        let(:server) { instance_double(::Aws::EC2::Instance, public_dns_name: "") }

        it "keeps the existing hostname and warns" do
          state[:hostname] = "10.0.0.5"
          driver.send(:instance_connect_configure_direct_ssh, state)

          expect(state[:hostname]).to eq("10.0.0.5")
          expect(logged_output.string).to match(/No public DNS available for direct SSH/)
        end
      end
    end

    describe "public key extraction" do
      let(:key_dir) { Dir.mktmpdir }
      let(:private_key_path) { File.join(key_dir, "kitchen.pem") }

      after { FileUtils.remove_entry(key_dir) }

      it "reads an adjacent .pub file when one exists" do
        File.write(private_key_path, "ignored")
        File.write("#{private_key_path}.pub", "ssh-rsa AAAAFROMFILE kitchen\n")

        expect(driver.send(:instance_connect_extract_public_key, private_key_path))
          .to eq("ssh-rsa AAAAFROMFILE kitchen")
      end

      # Keys created by `create_key` are downloaded as a bare private key with
      # no .pub alongside, so the public half has to be derived.
      it "derives the public key from the private key otherwise" do
        File.write(private_key_path, SSHKey.generate(type: "RSA", bits: 2048).private_key)

        expect(driver.send(:instance_connect_extract_public_key, private_key_path))
          .to start_with("ssh-rsa ")
      end

      it "raises a helpful error when the key cannot be read" do
        File.write(private_key_path, "not a key at all")

        expect { driver.send(:instance_connect_extract_public_key, private_key_path) }
          .to raise_error(/Unable to extract public key from/)
      end
    end
  end

  describe "SSM Session Manager" do
    def ssm_proxy_command(**overrides)
      transport = Kitchen::Transport::Dummy.new
      build_driver_with_instance(
        transport: transport,
        image_id: "ami-1",
        use_ssm_session_manager: true,
        **overrides
      )
      state = { server_id: "i-0123456789abcdef0" }
      transport.connection(state)
      state[:ssh_proxy_command]
    end

    it "proxies SSH through an SSM session" do
      expect(ssm_proxy_command).to eq(
        "aws ssm start-session --target i-0123456789abcdef0 --region us-west-2"
      )
    end

    it "uses a custom session document when one is configured" do
      expect(ssm_proxy_command(ssm_session_manager_document_name: "MySessionDoc"))
        .to include("--document-name MySessionDoc")
    end

    it "passes the shared credentials profile through" do
      expect(ssm_proxy_command(shared_credentials_profile: "kitchen")).to include("--profile kitchen")
    end

    # Without an instance there is nothing to target, so the transport is left
    # to connect however it normally would.
    it "sets no proxy command before the instance exists" do
      transport = Kitchen::Transport::Dummy.new
      build_driver_with_instance(transport: transport, image_id: "ami-1", use_ssm_session_manager: true)
      state = {}
      transport.connection(state)

      expect(state).not_to have_key(:ssh_proxy_command)
    end
  end
end
