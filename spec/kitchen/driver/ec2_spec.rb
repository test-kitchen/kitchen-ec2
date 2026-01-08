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

  describe "Instance Connect functionality" do
    let(:state) { { server_id: "i-12345", ssh_key: "/path/to/key.pem", username: "ec2-user" } }

    describe "#instance_connect_configure_ssh_proxy_command" do
      context "with instance_connect_endpoint_id configured" do
        let(:config) do
          {
            use_instance_connect: true,
            instance_connect_endpoint_id: "eice-12345",
            instance_connect_max_tunnel_duration: 3600,
            shared_credentials_profile: "my-profile",
            region: "us-east-1"
          }
        end

        it "sets up SSH proxy command with all parameters" do
          driver.send(:instance_connect_configure_ssh_proxy_command, state)
          expected_command = "aws ec2-instance-connect open-tunnel --instance-id i-12345 " \
                           "--instance-connect-endpoint-id eice-12345 --max-tunnel-duration 3600 " \
                           "--profile my-profile --region us-east-1"
          expect(state[:ssh_proxy_command]).to eq(expected_command)
        end

        it "stores instance connect config in state" do
          driver.send(:instance_connect_configure_ssh_proxy_command, state)
          expect(state[:instance_connect_config]).to eq({
            server_id: "i-12345",
            username: "ec2-user",
            region: "us-east-1",
            profile: "my-profile",
            tunnel_mode: true
          })
        end
      end

      context "with minimal configuration" do
        let(:config) do
          {
            use_instance_connect: true,
            region: "us-west-2"
          }
        end

        it "sets up SSH proxy command with minimal parameters" do
          driver.send(:instance_connect_configure_ssh_proxy_command, state)
          expected_command = "aws ec2-instance-connect open-tunnel --instance-id i-12345 --max-tunnel-duration 3600 --region us-west-2"
          expect(state[:ssh_proxy_command]).to eq(expected_command)
        end
      end
    end

    describe "#instance_connect_refresh_key" do
      let(:config) do
        {
          use_instance_connect: true,
          region: "us-east-1",
          shared_credentials_profile: "my-profile"
        }
      end

      before do
        allow(driver).to receive(:instance_connect_extract_public_key).with("/path/to/key.pem").and_return("ssh-rsa AAAAB3... test-key")
      end

      it "executes aws ec2-instance-connect send-ssh-public-key command" do
        expected_command = "aws ec2-instance-connect send-ssh-public-key " \
                         "--instance-id i-12345 --instance-os-user ec2-user " \
                         "--ssh-public-key ssh-rsa\\ AAAAB3...\\ test-key " \
                         "--region us-east-1 --profile my-profile"
        
        expect(driver).to receive(:`).with(expected_command + " 2>&1").and_return("")
        # Stub $? by allowing the actual command to succeed
        allow(driver).to receive(:warn)
        driver.send(:instance_connect_refresh_key, state)
      end

      it "handles command failure gracefully" do
        allow(driver).to receive(:`).and_return("Error: Something went wrong")
        expect(driver).to receive(:warn).with("[AWS EC2 Instance Connect] Failed to refresh SSH key: Error: Something went wrong")
        allow(driver).to receive(:`) do |cmd|
          # Simulate command failure by setting $? to failed status
          `false`
          "Error: Something went wrong"
        end
        
        driver.send(:instance_connect_refresh_key, state)
      end

      it "returns early if no key path is provided" do
        state.delete(:ssh_key)
        allow(instance.transport).to receive(:[]).with(:ssh_key).and_return(nil)
        expect(driver).not_to receive(:instance_connect_extract_public_key)
        expect(driver).not_to receive(:`)
        driver.send(:instance_connect_refresh_key, state)
      end
    end

    describe "#instance_connect_extract_public_key" do
      context "when .pub file exists" do
        it "reads the public key from .pub file" do
          allow(File).to receive(:exist?).with("/path/to/key.pem.pub").and_return(true)
          allow(File).to receive(:read).with("/path/to/key.pem.pub").and_return("ssh-rsa AAAAB3... test-key\n")
          result = driver.send(:instance_connect_extract_public_key, "/path/to/key.pem")
          expect(result).to eq("ssh-rsa AAAAB3... test-key")
        end
      end

      context "when .pub file does not exist" do
        before do
          allow(File).to receive(:exist?).with("/path/to/key.pem.pub").and_return(false)
          allow(File).to receive(:read).with("/path/to/key.pem").and_return("-----BEGIN RSA PRIVATE KEY-----\n...")
        end

        it "extracts public key from private key using SSHKey" do
          ssh_key_mock = double("SSHKey")
          allow(SSHKey).to receive(:new).with("-----BEGIN RSA PRIVATE KEY-----\n...").and_return(ssh_key_mock)
          allow(ssh_key_mock).to receive(:ssh_public_key).and_return("ssh-rsa AAAAB3... generated-key")
          result = driver.send(:instance_connect_extract_public_key, "/path/to/key.pem")
          expect(result).to eq("ssh-rsa AAAAB3... generated-key")
        end

        it "raises error if SSHKey fails" do
          allow(SSHKey).to receive(:new).and_raise(StandardError.new("Invalid key format"))
          expect { driver.send(:instance_connect_extract_public_key, "/path/to/key.pem") }
            .to raise_error("Unable to extract public key from /path/to/key.pem: Invalid key format")
        end
      end
    end

    describe "#instance_connect_setup_ready" do
      context "when endpoint is available (tunnel mode)" do
        let(:config) do
          {
            use_instance_connect: true,
            instance_connect_endpoint_id: "eice-12345",
            region: "us-east-1"
          }
        end

        before do
          allow(driver).to receive(:instance_connect_endpoint_available?).with(state).and_return(true)
        end

        it "configures SSH proxy command and refreshes key" do
          expect(driver).to receive(:instance_connect_configure_ssh_proxy_command).with(state)
          expect(driver).to receive(:instance_connect_refresh_key).with(state)
          expect(driver).to receive(:info).with("[AWS EC2 Instance Connect] Using tunnel mode - Instance Connect endpoint available")
          driver.send(:instance_connect_setup_ready, state)
        end

        context "when ssh_proxy_command is already set" do
          before do
            state[:ssh_proxy_command] = "existing-command"
          end

          it "skips SSH proxy command configuration but still refreshes key" do
            expect(driver).not_to receive(:instance_connect_configure_ssh_proxy_command)
            expect(driver).to receive(:instance_connect_refresh_key).with(state)
            expect(driver).to receive(:info).with("[AWS EC2 Instance Connect] Using tunnel mode - Instance Connect endpoint available")
            driver.send(:instance_connect_setup_ready, state)
          end
        end
      end

      context "when endpoint is not available (direct SSH mode)" do
        let(:config) do
          {
            use_instance_connect: true,
            region: "us-east-1"
          }
        end

        before do
          allow(driver).to receive(:instance_connect_endpoint_available?).with(state).and_return(false)
        end

        it "configures direct SSH and refreshes key" do
          expect(driver).to receive(:instance_connect_configure_direct_ssh).with(state)
          expect(driver).to receive(:instance_connect_refresh_key).with(state)
          expect(driver).to receive(:info).with("[AWS EC2 Instance Connect] Using direct SSH mode - no Instance Connect endpoint")
          driver.send(:instance_connect_setup_ready, state)
        end
      end
    end

    describe "#instance_connect_endpoint_available?" do
      let(:vpc_id) { "vpc-12345" }
      let(:state) { { server_id: "i-12345" } }
      
      before do
        allow(driver).to receive(:get_vpc_id_for_instance).with(state).and_return(vpc_id)
      end

      context "when instance_connect_endpoint_id is explicitly configured" do
        let(:config) { { instance_connect_endpoint_id: "eice-12345" } }

        it "returns true without checking VPC endpoints" do
          expect(actual_client).not_to receive(:describe_instance_connect_endpoints)
          result = driver.send(:instance_connect_endpoint_available?, state)
          expect(result).to be true
        end
      end

      context "when no explicit endpoint_id is configured" do
        let(:config) { {} }

        context "and VPC has active endpoints" do
          let(:endpoints) { [double("endpoint", state: "create-complete")] }

          before do
            allow(actual_client).to receive(:describe_instance_connect_endpoints).with(
              filters: [
                { name: "vpc-id", values: [vpc_id] },
                { name: "state", values: ["create-complete"] }
              ]
            ).and_return(double(instance_connect_endpoints: endpoints))
          end

          it "returns true" do
            result = driver.send(:instance_connect_endpoint_available?, state)
            expect(result).to be true
          end
        end

        context "and VPC has no active endpoints" do
          before do
            allow(actual_client).to receive(:describe_instance_connect_endpoints).with(
              filters: [
                { name: "vpc-id", values: [vpc_id] },
                { name: "state", values: ["create-complete"] }
              ]
            ).and_return(double(instance_connect_endpoints: []))
          end

          it "returns false" do
            result = driver.send(:instance_connect_endpoint_available?, state)
            expect(result).to be false
          end
        end

        context "and endpoint checking fails" do
          before do
            allow(actual_client).to receive(:describe_instance_connect_endpoints)
              .and_raise(Aws::EC2::Errors::InvalidAction.new("context", "Not supported in this region"))
          end

          it "returns false and logs debug message" do
            expect(driver).to receive(:debug).with("[AWS EC2 Instance Connect] Cannot check for endpoints: Not supported in this region")
            result = driver.send(:instance_connect_endpoint_available?, state)
            expect(result).to be false
          end
        end

        context "and no VPC ID is available" do
          before do
            allow(driver).to receive(:get_vpc_id_for_instance).with(state).and_return(nil)
          end

          it "returns false" do
            expect(actual_client).not_to receive(:describe_instance_connect_endpoints)
            result = driver.send(:instance_connect_endpoint_available?, state)
            expect(result).to be false
          end
        end
      end
    end

    describe "#get_vpc_id_for_instance" do
      let(:state) { { server_id: "i-12345" } }
      let(:instance_info) { double("instance", vpc_id: "vpc-12345") }
      let(:reservation) { double("reservation", instances: [instance_info]) }

      context "when instance exists" do
        before do
          allow(actual_client).to receive(:describe_instances).with(instance_ids: ["i-12345"])
            .and_return(double(reservations: [reservation]))
        end

        it "returns the VPC ID" do
          result = driver.send(:get_vpc_id_for_instance, state)
          expect(result).to eq("vpc-12345")
        end
      end

      context "when instance does not exist" do
        before do
          allow(actual_client).to receive(:describe_instances).with(instance_ids: ["i-12345"])
            .and_return(double(reservations: []))
        end

        it "returns nil" do
          result = driver.send(:get_vpc_id_for_instance, state)
          expect(result).to be_nil
        end
      end

      context "when server_id is not present" do
        let(:state) { {} }

        it "returns nil" do
          expect(actual_client).not_to receive(:describe_instances)
          result = driver.send(:get_vpc_id_for_instance, state)
          expect(result).to be_nil
        end
      end

      context "when API call fails" do
        before do
          allow(actual_client).to receive(:describe_instances)
            .and_raise(StandardError.new("API Error"))
        end

        it "returns nil and logs debug message" do
          expect(driver).to receive(:debug).with("[AWS EC2 Instance Connect] Error getting VPC ID for instance: API Error")
          result = driver.send(:get_vpc_id_for_instance, state)
          expect(result).to be_nil
        end
      end
    end

    describe "#instance_connect_configure_direct_ssh" do
      let(:state) { { server_id: "i-12345", username: "ec2-user" } }
      let(:server) { double("server", public_dns_name: "ec2-1-2-3-4.compute-1.amazonaws.com") }
      let(:config) do
        {
          region: "us-east-1",
          shared_credentials_profile: "my-profile"
        }
      end

      before do
        allow(client).to receive(:get_instance).with("i-12345").and_return(server)
      end

      context "when public DNS is available" do
        it "sets hostname to public DNS and stores config" do
          expect(driver).to receive(:info).with("[AWS EC2 Instance Connect] Configuring direct SSH to ec2-1-2-3-4.compute-1.amazonaws.com")
          driver.send(:instance_connect_configure_direct_ssh, state)
          
          expect(state[:hostname]).to eq("ec2-1-2-3-4.compute-1.amazonaws.com")
          expect(state[:instance_connect_config]).to eq({
            server_id: "i-12345",
            username: "ec2-user",
            region: "us-east-1",
            profile: "my-profile",
            direct_ssh: true,
            hostname: "ec2-1-2-3-4.compute-1.amazonaws.com"
          })
        end
      end

      context "when public DNS is not available" do
        let(:server) { double("server", public_dns_name: nil) }

        it "warns and does not change hostname" do
          original_hostname = state[:hostname]
          expect(driver).to receive(:warn).with("[AWS EC2 Instance Connect] No public DNS available for direct SSH, falling back to existing hostname")
          driver.send(:instance_connect_configure_direct_ssh, state)
          
          expect(state[:hostname]).to eq(original_hostname)
        end
      end

      context "when public DNS is empty string" do
        let(:server) { double("server", public_dns_name: "") }

        it "warns and does not change hostname" do
          original_hostname = state[:hostname]
          expect(driver).to receive(:warn).with("[AWS EC2 Instance Connect] No public DNS available for direct SSH, falling back to existing hostname")
          driver.send(:instance_connect_configure_direct_ssh, state)
          
          expect(state[:hostname]).to eq(original_hostname)
        end
      end
    end

    describe "integration with create method" do
      let(:server) { double("aws server object", id: "i-12345") }
      let(:create_state) { { ssh_key: "/path/to/key.pem", username: "ec2-user" } }
      let(:config) do
        {
          use_instance_connect: true,
          instance_connect_endpoint_id: "eice-12345",
          region: "us-east-1",
          aws_ssh_key_id: "test-key",
          image_id: "ami-12345",
          security_group_ids: ["sg-12345"]
        }
      end

      before do
        allow(driver).to receive(:update_username)
        allow(driver).to receive(:submit_server).and_return(server)
        allow(server).to receive(:wait_until_exists)
        allow(driver).to receive(:attach_network_interface)
        allow(driver).to receive(:create_ec2_json)
        allow(driver).to receive(:debug)
        allow(driver).to receive(:info)
        
        # Stub methods that might cause early exits
        allow(driver).to receive(:create_security_group)
        allow(driver).to receive(:create_key)
        allow(driver).to receive(:host_available?).and_return(true)
        
        # Stub wait_until_ready and the Retryable wrapper
        allow(driver).to receive(:wait_until_ready) do |_, state|
          state[:hostname] = "test-hostname"
          true
        end
        
        # Allow the Retryable block to execute normally
        allow(Retryable).to receive(:retryable) do |options, &block|
          block.call(1, nil)
        end

        # Mock the transport connection wait_until_ready call
        connection_double = double("connection", wait_until_ready: true)
        allow(instance.transport).to receive(:connection).with(any_args).and_return(connection_double)
      end

      it "calls instance_connect_setup_ready when use_instance_connect is true" do
        expect(driver).to receive(:instance_connect_setup_ready).with(hash_including(server_id: "i-12345"))
        driver.create(create_state)
      end

      it "does not call instance_connect_setup_ready when use_instance_connect is false" do
        config[:use_instance_connect] = false
        expect(driver).not_to receive(:instance_connect_setup_ready)
        driver.create(create_state)
      end
    end
  end

  describe "SSM Session Manager functionality" do
    describe "integration with create method" do
      let(:ssm_manager) { instance_double(Kitchen::Driver::Aws::SsmSessionManager) }
      let(:create_state) { {} }
      let(:config) do
        {
          use_ssm_session_manager: true,
          region: "us-east-1",
          aws_ssh_key_id: "test-key",
          image_id: "ami-12345",
          security_group_ids: ["sg-12345"],
        }
      end

      before do
        allow(driver).to receive(:update_username)
        allow(driver).to receive(:submit_server).and_return(server)
        allow(server).to receive(:wait_until_exists)
        allow(server).to receive(:id).and_return("i-12345")
        allow(driver).to receive(:attach_network_interface)
        allow(driver).to receive(:create_ec2_json)
        allow(driver).to receive(:debug)
        allow(driver).to receive(:info)
        allow(driver).to receive(:create_security_group)
        allow(driver).to receive(:create_key)
        allow(driver).to receive(:host_available?).and_return(true)
        allow(driver).to receive(:ssm_session_manager).and_return(ssm_manager)
        
        allow(driver).to receive(:wait_until_ready) do |_, state|
          state[:hostname] = "test-hostname"
          true
        end
        
        allow(Retryable).to receive(:retryable) do |_options, &block|
          block.call(1, nil)
        end

        connection_double = double("connection", wait_until_ready: true)
        allow(instance.transport).to receive(:connection).with(any_args).and_return(connection_double)
      end

      it "calls ssm_session_manager_setup_ready when use_ssm_session_manager is true" do
        expect(driver).to receive(:ssm_session_manager_setup_ready).with(hash_including(server_id: "i-12345"))
        driver.create(create_state)
      end

      it "does not call ssm_session_manager_setup_ready when use_ssm_session_manager is false" do
        config[:use_ssm_session_manager] = false
        expect(driver).not_to receive(:ssm_session_manager_setup_ready)
        driver.create(create_state)
      end
    end

    describe "#ssm_session_manager_setup_ready" do
      let(:state) { { server_id: "i-12345" } }
      let(:ssm_manager) { instance_double(Kitchen::Driver::Aws::SsmSessionManager) }

      before do
        allow(driver).to receive(:ssm_session_manager).and_return(ssm_manager)
        allow(driver).to receive(:info)
        allow(driver).to receive(:warn)
        allow(ssm_manager).to receive(:session_manager_plugin_installed?).and_return(true)
      end

      context "when SSM agent is available immediately" do
        it "does not wait" do
          expect(ssm_manager).to receive(:ssm_agent_available?).with("i-12345").and_return(true)
          expect(driver).not_to receive(:sleep)
          driver.send(:ssm_session_manager_setup_ready, state)
        end
      end

      context "when SSM agent becomes available after retries" do
        it "waits and succeeds" do
          call_count = 0
          allow(ssm_manager).to receive(:ssm_agent_available?) do |_instance_id|
            call_count += 1
            call_count > 2
          end
          
          expect(driver).to receive(:sleep).twice
          driver.send(:ssm_session_manager_setup_ready, state)
        end
      end

      context "when session manager plugin is not installed" do
        it "warns the user" do
          allow(ssm_manager).to receive(:session_manager_plugin_installed?).and_return(false)
          allow(ssm_manager).to receive(:ssm_agent_available?).and_return(true)
          
          expect(driver).to receive(:warn).with(/Session Manager plugin not found/)
          driver.send(:ssm_session_manager_setup_ready, state)
        end
      end
    end

    describe "#ssm_session_manager_setup_override" do
      let(:state) { { server_id: "i-12345" } }
      let(:config) do
        {
          use_ssm_session_manager: true,
          region: "us-west-2",
          shared_credentials_profile: "my-profile",
        }
      end

      before do
        allow(driver).to receive(:info)
      end

      it "overrides transport connection method" do
        expect(instance.transport).to receive(:define_singleton_method).with(:connection)
        expect(instance.transport).to receive(:define_singleton_method).with(:ssm_session_manager_override_applied)
        driver.send(:ssm_session_manager_setup_override, instance)
      end

      it "sets SSH proxy command with correct parameters" do
        driver.send(:ssm_session_manager_setup_override, instance)
        
        # Call the overridden connection method
        original_method = instance.transport.method(:connection)
        allow(original_method).to receive(:call)
        
        instance.transport.connection(state)
        
        expect(state[:ssh_proxy_command]).to include("aws ssm start-session")
        expect(state[:ssh_proxy_command]).to include("--target i-12345")
        expect(state[:ssh_proxy_command]).to include("--region us-west-2")
        expect(state[:ssh_proxy_command]).to include("--profile my-profile")
      end

      it "includes document name when specified" do
        config[:ssm_session_manager_document_name] = "MyCustomDocument"
        driver.send(:ssm_session_manager_setup_override, instance)
        
        instance.transport.connection(state)
        
        expect(state[:ssh_proxy_command]).to include("--document-name MyCustomDocument")
      end

      it "does not apply override twice" do
        driver.send(:ssm_session_manager_setup_override, instance)
        expect(instance.transport).to respond_to(:ssm_session_manager_override_applied)
        
        # Second call should return early
        expect(instance.transport).not_to receive(:define_singleton_method)
        driver.send(:ssm_session_manager_setup_override, instance)
      end
    end
  end
end
