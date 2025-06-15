#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright:: 2015-2018, Fletcher Nichol
# Copyright:: 2016-2018, Chef Software, Inc.
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
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

describe Kitchen::Driver::Ec2 do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }
  let(:config) do
    {
      aws_ssh_key_id: "key",
      image_id: "ami-1234567",
      block_duration_minutes: 60,
      subnet_id: "subnet-1234",
      security_group_ids: ["sg-56789"],
    }
  end
  let(:platform)      { Kitchen::Platform.new(name: "fooos-99") }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:provisioner)   { Kitchen::Provisioner::Dummy.new }
  let(:generator)     { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
  # There is too much name overlap I let creep in - my `client` is actually
  # a wrapper around the actual ec2 client
  let(:actual_client) { double("actual ec2 client") }
  let(:client)        { double(Kitchen::Driver::Aws::Client, client: actual_client) }
  let(:server) { double("aws server object") }
  let(:state) { {} }

  let(:driver) { Kitchen::Driver::Ec2.new(config) }

  let(:instance) do
    instance_double(
      Kitchen::Instance,
      logger: logger,
      transport: transport,
      provisioner: provisioner,
      platform: platform,
      to_str: "str"
    )
  end

  before do
    allow(Kitchen::Driver::Aws::InstanceGenerator).to receive(:new).and_return(generator)
    allow(Kitchen::Driver::Aws::Client).to receive(:new).and_return(client)
    allow(driver).to receive(:windows_os?).and_return(false)
    allow(driver).to receive(:instance).and_return(instance)
  end

  it "driver api_version is 2" do
    expect(driver.diagnose_plugin[:api_version]).to eq(2)
  end

  it "plugin_version is set to Kitchen::Vagrant::VERSION" do
    expect(driver.diagnose_plugin[:version]).to eq(
      Kitchen::Driver::EC2_VERSION
    )
  end

  describe "default_config" do
    context "Windows" do
      let(:resource) { instance_double(Aws::EC2::Resource, image: image) }
      before do
        allow(driver).to receive(:windows_os?).and_return(true)
        allow(client).to receive(:resource).and_return(resource)
        allow(instance).to receive(:name).and_return("instance_name")
      end
      context "Windows 2016" do
        let(:image) do
          FakeImage.new(name: "Windows_Server-2016-English-Full-Base-2017.01.11")
        end
        it "sets :user_data to something" do
          expect(driver[:user_data]).to include("$logfile='C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log\\kitchen-ec2.log'")
        end
      end
      context "Windows 2019" do
        let(:image) do
          FakeImage.new(name: "Windows_Server-2019-English-Full-Base-2019.06.12")
        end
        it "sets :user_data to something" do
          expect(driver[:user_data]).to include("$logfile='C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log\\kitchen-ec2.log'")
        end
      end
      context "Windows 2012R2" do
        let(:image) do
          FakeImage.new(name: "Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.01.11")
        end
        it "sets :user_data to something" do
          expect(driver[:user_data]).to include("$logfile='C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs\\kitchen-ec2.log'")
        end
      end
    end
  end

  describe "#hostname" do
    let(:public_dns_name) { nil }
    let(:private_dns_name) { nil }
    let(:public_ip_address) { nil }
    let(:private_ip_address) { nil }
    let(:id) { nil }
    let(:server) do
      double("server",
        public_dns_name: public_dns_name,
        private_dns_name: private_dns_name,
        public_ip_address: public_ip_address,
        private_ip_address: private_ip_address,
        id: id)
    end

    it "returns nil if all sources are nil" do
      expect(driver.hostname(server)).to eq(nil)
    end

    it "raises an error if provided an unknown interface" do
      expect { driver.hostname(server, "foobar") }.to raise_error(Kitchen::UserError)
    end

    shared_examples "an interface type provided" do
      it "returns public_dns_name when requested" do
        expect(driver.hostname(server, "dns")).to eq(public_dns_name)
      end
      it "returns public_ip_address when requested" do
        expect(driver.hostname(server, "public")).to eq(public_ip_address)
      end
      it "returns private_ip_address when requested" do
        expect(driver.hostname(server, "private")).to eq(private_ip_address)
      end
      it "returns private_dns_name when requested" do
        expect(driver.hostname(server, "private_dns")).to eq(private_dns_name)
      end
      it "returns id when requested" do
        expect(driver.hostname(server, "id")).to eq(id)
      end
    end

    context "private_dns_name is populated" do
      let(:private_dns_name) { "private_dns_name" }

      it "returns the private_dns_name" do
        expect(driver.hostname(server)).to eq(private_dns_name)
      end

      include_examples "an interface type provided"
    end

    context "private_ip_address is populated" do
      let(:private_dns_name) { "private_dns_name" }
      let(:private_ip_address) { "10.0.0.1" }

      it "returns the private_ip_address" do
        expect(driver.hostname(server)).to eq(private_ip_address)
      end

      include_examples "an interface type provided"
    end

    context "public_ip_address is populated" do
      let(:private_dns_name) { "private_dns_name" }
      let(:private_ip_address) { "10.0.0.1" }
      let(:public_ip_address) { "127.0.0.1" }

      it "returns the public_ip_address" do
        expect(driver.hostname(server)).to eq(public_ip_address)
      end

      include_examples "an interface type provided"
    end

    context "public_dns_name is populated" do
      let(:private_dns_name) { "private_dns_name" }
      let(:private_ip_address) { "10.0.0.1" }
      let(:public_ip_address) { "127.0.0.1" }
      let(:public_dns_name) { "public_dns_name" }

      it "returns the public_dns_name" do
        expect(driver.hostname(server)).to eq(public_dns_name)
      end

      include_examples "an interface type provided"
    end

    context "public_dns_name returns as empty string" do
      let(:public_dns_name) { "" }
      it "returns nil" do
        expect(driver.hostname(server)).to eq(nil)
      end

      context "and private_ip_address is populated" do
        let(:private_ip_address) { "10.0.0.1" }
        it "returns the private_ip_address" do
          expect(driver.hostname(server)).to eq(private_ip_address)
        end

        context "and private_dns_name is populated" do
          let(:private_dns_name) { "private_dns_name" }
          it "returns the private_ip_address" do
            expect(driver.hostname(server)).to eq(private_ip_address)
          end
        end
      end
    end
  end

  describe "#submit_server" do
    before do
      expect(driver).to receive(:instance).at_least(:once).and_return(instance)
    end

    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return({})
      expect(client).to receive(:create_instance)
      driver.submit_server
    end
  end

  describe "submit_server with terminate shutdown behaviour" do
    before do
      config[:instance_initiated_shutdown_behavior] = "terminate"
      expect(driver).to receive(:instance).at_least(:once).and_return(instance)
    end

    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return(
        { instance_initiated_shutdown_behavior: "terminate" }
      )
      expect(client).to receive(:create_instance).with(
        { instance_initiated_shutdown_behavior: "terminate" }
      )
      driver.submit_server
    end
  end

  describe "#submit_spot" do
    before do
      expect(driver).to receive(:instance).at_least(:once).and_return(instance)
    end

    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return({})
      expect(client).to receive(:create_instance).with({
        instance_market_options: {
          market_type: "spot",
          spot_options: {
            block_duration_minutes: 60,
          },
        },
      }).and_return(server)
      driver.submit_spot
    end
  end

  describe "#wait_until_ready" do
    let(:hostname) { "0.0.0.0" }
    let(:msg) { "to become ready" }
    let(:aws_instance) { double("aws instance") }

    before do
      config[:interface] = :i
      expect(driver).to receive(:wait_with_destroy).with(server, state, msg).and_yield(aws_instance)
      expect(driver).to receive(:hostname).with(aws_instance, :i).and_return(hostname)
    end

    after do
      expect(state[:hostname]).to eq(hostname)
    end

    it "first checks instance existence" do
      expect(aws_instance).to receive(:exists?).and_return(false)
      expect(driver.wait_until_ready(server, state)).to eq(false)
    end

    it "second checks instance state" do
      expect(aws_instance).to receive(:exists?).and_return(true)
      expect(aws_instance).to receive_message_chain("state.name").and_return("nope")
      expect(driver.wait_until_ready(server, state)).to eq(false)
    end

    it "third checks hostname" do
      expect(aws_instance).to receive(:exists?).and_return(true)
      expect(aws_instance).to receive_message_chain("state.name").and_return("running")
      expect(driver.wait_until_ready(server, state)).to eq(false)
    end

    context "when it exists, has a valid state and a valid hostname" do
      let(:hostname) { "host" }

      it "returns true" do
        expect(aws_instance).to receive(:exists?).and_return(true)
        expect(aws_instance).to receive_message_chain("state.name").and_return("running")
        expect(driver.wait_until_ready(server, state)).to eq(true)
      end
    end

    context "when windows instance" do
      let(:hostname) { "windows" }

      before do
        expect(aws_instance).to receive(:exists?).and_return(true)
        expect(aws_instance).to receive_message_chain("state.name").and_return("running")
        expect(driver).to receive(:windows_os?).and_return(true)
      end

      context "does define a username/password" do
        before do
          expect(transport).to receive(:[]).with(:username).and_return("foo")
        end

        context "console output is ready" do
          it "returns true" do
            # base64 encoded `Windows is Ready to use`
            expect(server).to receive_message_chain("console_output.output").and_return("V2luZG93cyBpcyBSZWFkeSB0byB1c2U=")
            expect(driver.wait_until_ready(server, state)).to eq(true)
          end
        end

        context "console output is not ready" do
          it "returns false" do
            expect(server).to receive_message_chain("console_output.output").and_return("")
            expect(driver.wait_until_ready(server, state)).to eq(false)
          end
        end
      end

      context "does not define a username/password" do
        it "returns true" do
          expect(transport).to receive(:[]).with(:username).and_return("administrator")
          expect(transport).to receive(:[]).with(:password).and_return(nil)
          expect(driver).to receive(:fetch_windows_admin_password).with(server, state)
          expect(driver.wait_until_ready(server, state)).to eq(true)
        end
      end
    end
  end

  describe "#fetch_windows_admin_password" do
    let(:msg) { "to fetch windows admin password" }
    let(:aws_instance) { double("aws instance") }
    let(:server_id) { "server_id" }
    let(:encrypted_password) { "alksdofw" }
    let(:data) { double("data", password_data: encrypted_password) }
    let(:password) { "password" }
    let(:transport) { { ssh_key: "foo" } }

    before do
      state[:server_id] = server_id
      expect(driver).to receive(:wait_with_destroy).with(server, state, msg).and_yield(aws_instance)
    end

    after do
      expect(state[:password]).to eq(password)
    end

    it "fetches and decrypts the windows password" do
      expect(server).to receive_message_chain("client.get_password_data").with(
        instance_id: server_id
      ).and_return(data)
      expect(server).to receive(:decrypt_windows_password)
        .with(File.expand_path("foo"))
        .and_return(password)
      driver.fetch_windows_admin_password(server, state)
    end
  end

  describe "#wait_with_destroy" do
    let(:tries) { 111 }
    let(:sleep) { 222 }
    let(:msg) { "msg" }
    given_block = lambda { ; }

    before do
      config[:retryable_sleep] = sleep
      config[:retryable_tries] = tries
    end

    it "calls wait and exits successfully if there is no error" do
      expect(server).to receive(:wait_until) do |args, &block|
        expect(args[:max_attempts]).to eq(tries)
        expect(args[:delay]).to eq(sleep)
        expect(block).to eq(given_block)
        expect(driver).to receive(:info).with(/#{msg}/)
        args[:before_attempt].call(0)
      end
      driver.wait_with_destroy(server, state, msg, &given_block)
    end

    it "attempts to destroy the instance if the waiter fails" do
      expect(server).to receive(:wait_until).and_raise(Aws::Waiters::Errors::WaiterFailed)
      expect(driver).to receive(:destroy).with(state)
      expect(driver).to receive(:error).with(/#{msg}/)
      expect do
        driver.wait_with_destroy(server, state, msg, &given_block)
      end.to raise_error(Aws::Waiters::Errors::WaiterFailed)
    end
  end

  describe "#create_key" do
    context "creates a key pair via the ec2 API, saves the generated key locally" do
      before do
        config[:kitchen_root] = "/kitchen"
        config.delete(:aws_ssh_key_id)
        allow(instance).to receive(:name).and_return("instance_name")

        expect(actual_client).to receive(:create_key_pair).with(
            key_name: /kitchen-/,
            key_type: "rsa",
            tag_specifications: [{ resource_type: "key-pair", tags: [{ key: "created-by", value: "test-kitchen" }] }]
          ).and_return(double(key_name: "expected-key-name", key_material: "RSA PRIVATE KEY"))
        fake_file = double
        allow(File).to receive(:open).and_call_original
        expect(File).to receive(:open).with("/kitchen/.kitchen/instance_name.pem", kind_of(Numeric), kind_of(Numeric)).and_yield(fake_file)
        expect(fake_file).to receive(:write).with("RSA PRIVATE KEY")
      end

      it "generates a temporary SSH key pair for the instance" do
        driver.send(:create_key, state)
        expect(state[:auto_key_id]).to eq("expected-key-name")
        expect(state[:ssh_key]).to eq("/kitchen/.kitchen/instance_name.pem")
      end
    end
  end

  describe "#create" do
    let(:server) { double("aws server object", id: id, image_id: "ami-3f807145") }
    let(:id) { "i-12345" }

    it "returns if the instance is already created" do
      state[:server_id] = id
      expect(driver.create(state)).to eq(nil)
    end

    image_data = Aws::EC2::Types::Image.new(root_device_type: "ebs")
    ec2_stub = Aws::EC2::Types::DescribeImagesResult.new
    ec2_stub.images = [image_data]

    shared_examples "common create" do
      it "successfully creates and tags the instance" do
        expect(server).to receive(:wait_until_exists)
        expect(driver).to receive(:update_username)
        expect(driver).to receive(:wait_until_ready).with(server, state)
        expect(transport).to receive_message_chain("connection.wait_until_ready")
        driver.create(state)
        expect(state[:server_id]).to eq(id)
      end
    end

    context "chef provisioner" do
      let(:provisioner) { double("chef provisioner", name: "chef_solo") }

      before do
        expect(driver).to receive(:create_ec2_json).with(state)
        expect(driver).to receive(:submit_server).and_return(server)
      end

      include_examples "common create"
    end

    context "non-windows on-demand instance" do
      before do
        expect(driver).to receive(:submit_server).and_return(server)
      end

      include_examples "common create"
    end

    context "config is for a spot instance" do
      before do
        config[:spot_price] = 1
      end

      context "price is numeric" do
        before do
          expect(driver).to receive(:submit_spots).and_return(server)
        end

        include_examples "common create"
      end

      context "price is on-demand" do
        before do
          config[:spot_price] = "on-demand"
          expect(driver).to receive(:submit_spots).and_return(server)
        end

        include_examples "common create"
      end

      context "instance_type is an array" do
        before do
          config[:instance_type] = %w{t1 t2}
          expect(driver).to receive(:submit_spot).and_return(server)
        end

        include_examples "common create"

        context "subnets is also an array" do
          before do
            config[:subnet_id] = %w{t1 t2}
          end

          include_examples "common create"
        end
      end
    end

    context "instance is a windows machine" do
      before do
        expect(driver).to receive(:submit_server).and_return(server)
      end

      include_examples "common create"
    end

    context "instance is not a standard platform" do
      let(:state) { {} }
      before do
        expect(driver).to receive(:actual_platform).and_return(nil)
      end

      it "doesn't set the state username" do
        driver.update_username(state)
        expect(state).to eq({})
      end
    end

    context "with no security group specified" do
      before do
        config.delete(:security_group_ids)
        expect(driver).to receive(:submit_server).and_return(server)
        allow(instance).to receive(:name).and_return("instance_name")
      end

      context "with a subnet configured" do
        before do
          expect(actual_client).to receive(:describe_subnets).with(filters: [{ name: "subnet-id", values: ["subnet-1234"] }]).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end

      context "with a subnet filter configured" do
        before do
          config.delete(:subnet_id)
          config[:subnet_filter] = {
            tag: "foo",
            value: "bar",
          }
          expect(actual_client).to receive(:describe_subnets).with({ filters: [{ name: "tag:foo", values: ["bar"] }] }).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end

      context "with multiple subnet filters configured" do
        before do
          config.delete(:subnet_id)
          config[:subnet_filter] = [{
            tag: "foo",
            value: "bar",
          },
          {
            tag: "hello",
            value: "world",
          }]
          expect(actual_client).to receive(:describe_subnets).with({ filters: [{ name: "tag:foo", values: ["bar"] }, { name: "tag:hello", values: ["world"] }] }).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end

      context "with an ip address configured as a string" do
        before do
          config[:security_group_cidr_ip] = "1.2.3.4/32"
          expect(actual_client).to receive(:describe_subnets).with(filters: [{ name: "subnet-id", values: ["subnet-1234"] }]).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "1.2.3.4/32" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "1.2.3.4/32" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "1.2.3.4/32" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "1.2.3.4/32" }] },
          ])
        end

        include_examples "common create"
      end

      context "with an ip address configured as an array" do
        before do
          config[:security_group_cidr_ip] = ["10.0.0.0/22"]
          expect(actual_client).to receive(:describe_subnets).with(filters: [{ name: "subnet-id", values: ["subnet-1234"] }]).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }] },
          ])
        end

        include_examples "common create"
      end

      context "with multiple ip addresses configured as an array" do
        before do
          config[:security_group_cidr_ip] = ["10.0.0.0/22", "172.16.0.0/24"]
          expect(actual_client).to receive(:describe_subnets).with(filters: [{ name: "subnet-id", values: ["subnet-1234"] }]).and_return(double(subnets: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }, { cidr_ip: "172.16.0.0/24" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }, { cidr_ip: "172.16.0.0/24" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }, { cidr_ip: "172.16.0.0/24" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "10.0.0.0/22" }, { cidr_ip: "172.16.0.0/24" }] },
          ])
        end

        include_examples "common create"
      end

      context "with a default VPC" do
        before do
          config.delete(:subnet_id)
          expect(actual_client).to receive(:describe_vpcs).with(filters: [{ name: "isDefault", values: ["true"] }]).and_return(double(vpcs: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              vpc_id: "vpc-1",
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end

      context "without a default VPC" do
        before do
          config.delete(:subnet_id)
          expect(actual_client).to receive(:describe_vpcs).with(filters: [{ name: "isDefault", values: ["true"] }]).and_return(double(vpcs: []))
          expect(actual_client).to receive(:create_security_group).with({
              group_name: /kitchen-/,
              description: /Test Kitchen for/,
              tag_specifications: [{ resource_type: "security-group", tags: [{ key: "created-by", value: "test-kitchen" }] }],
            }).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 3389, to_port: 3389, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end
    end

    context "with no security group but filter specified" do
      before do
        config.delete(:security_group_ids)
        config[:security_group_filter] = { tag: "SomeTag", value: "SomeValue" }
        expect(driver).not_to receive(:create_security_group)
        expect(driver).to receive(:submit_server).and_return(server)
        allow(instance).to receive(:name).and_return("instance_name")
      end

      include_examples "common create"
    end

    context "and AWS SSH keys" do
      before do
        allow(driver).to receive(:submit_server).and_return(server)
        allow(instance).to receive(:name).and_return("instance_name")
      end

      context "with no AWS-managed ssh key pair configured, creates a key pair to use" do
        before do
          config[:aws_ssh_key_id] = nil
          expect(driver).to receive(:create_key)
          state[:auto_key_id] = "autogenerated_by_create_key"
        end

        after do
          expect(config[:aws_ssh_key_id]).to eq("autogenerated_by_create_key")
        end

        include_examples "common create"
      end

      context "with AWS-managed ssh key pair disabled, does not create a key pair or pass a key id" do
        before do
          config[:aws_ssh_key_id] = "_disable"
          expect(driver).to_not receive(:create_key)
        end

        after do
          expect(config[:aws_ssh_key_id]).to be_nil
        end

        include_examples "common create"
      end

      context "with AWS ssh key pair set, uses set key and does not create a key pair" do
        before do
          config[:aws_ssh_key_id] = "use_this_key_please"
          expect(driver).to_not receive(:create_key)
        end

        after do
          expect(config[:aws_ssh_key_id]).to eq("use_this_key_please")
        end

        include_examples "common create"
      end
    end
  end

  describe "#destroy" do
    context "when state[:server_id] is nil" do
      it "returns nil" do
        expect(driver.destroy(state)).to eq(nil)
      end
    end

    context "when state has a normal server_id" do
      let(:state) { { server_id: "id", hostname: "name" } }

      context "the server is already destroyed" do
        it "does nothing" do
          expect(client).to receive(:get_instance).with("id").and_return nil
          driver.destroy(state)
          expect(state).to eq({})
        end
      end

      it "destroys the server" do
        expect(client).to receive(:get_instance).with("id").and_return(server)
        expect(instance).to receive_message_chain("transport.connection.close")
        expect(server).to receive(:terminate)
        driver.destroy(state)
        expect(state).to eq({})
      end
    end

    context "when the state has an automatic security group" do
      let(:state) { { auto_security_group_id: "sg-asdf" } }

      it "destroys the security group" do
        expect(actual_client).to receive(:delete_security_group).with(group_id: "sg-asdf")
        driver.destroy(state)
        expect(state).to eq({})
      end
    end

    context "when the state has an automatic key pair" do
      let(:state) { { auto_key_id: "kitchen-asdf" } }

      it "destroys the key pair" do
        config[:kitchen_root] = "/kitchen"
        allow(instance).to receive(:name).and_return("instance_name")
        expect(actual_client).to receive(:delete_key_pair).with(key_name: "kitchen-asdf")
        expect(File).to receive(:unlink).with("/kitchen/.kitchen/instance_name.pem")
        driver.destroy(state)
        expect(state).to eq({})
      end
    end
  end
end
