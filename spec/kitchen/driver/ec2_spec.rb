# -*- encoding: utf-8 -*-
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
#    http://www.apache.org/licenses/LICENSE-2.0
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
      :aws_ssh_key_id => "key",
      :image_id => "ami-1234567",
      :block_duration_minutes => 60,
      :subnet_id => "subnet-1234",
      :security_group_ids => ["sg-56789"],
    }
  end
  let(:platform)      { Kitchen::Platform.new(:name => "fooos-99") }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:provisioner)   { Kitchen::Provisioner::Dummy.new }
  let(:generator)     { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
  # There is too much name overlap I let creep in - my `client` is actually
  # a wrapper around the actual ec2 client
  let(:actual_client) { double("actual ec2 client") }
  let(:client)        { double(Kitchen::Driver::Aws::Client, :client => actual_client) }
  let(:server) { double("aws server object") }
  let(:state) { {} }

  let(:driver) { Kitchen::Driver::Ec2.new(config) }

  let(:instance) do
    instance_double(
      Kitchen::Instance,
      :logger => logger,
      :transport => transport,
      :provisioner => provisioner,
      :platform => platform,
      :to_str => "str"
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
      Kitchen::Driver::EC2_VERSION)
  end

  describe "default_config" do
    context "Windows" do
      let(:resource) { instance_double(::Aws::EC2::Resource, :image => image) }
      before do
        allow(driver).to receive(:windows_os?).and_return(true)
        allow(client).to receive(:resource).and_return(resource)
        allow(instance).to receive(:name).and_return("instance_name")
      end
      context "Windows 2016" do
        let(:image) do
          FakeImage.new(:name => "Windows_Server-2016-English-Full-Base-2017.01.11")
        end
        it "sets :user_data to something" do
          expect(driver[:user_data]).to include
          '$logfile=C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log\\kitchen-ec2.log'
        end
      end
      context "Windows 2012R2" do
        let(:image) do
          FakeImage.new(:name => "Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.01.11")
        end
        it "sets :user_data to something" do
          expect(driver[:user_data]).to include
          '$logfile=C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs\\kitchen-ec2.log'
        end
      end
    end
  end

  describe "#hostname" do
    let(:public_dns_name) { nil }
    let(:private_dns_name) { nil }
    let(:public_ip_address) { nil }
    let(:private_ip_address) { nil }
    let(:server) do
      double("server",
        :public_dns_name => public_dns_name,
        :private_dns_name => private_dns_name,
        :public_ip_address => public_ip_address,
        :private_ip_address => private_ip_address
      )
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
      expect(client).to receive(:create_instance).with(:min_count => 1, :max_count => 1)
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
        :instance_initiated_shutdown_behavior => "terminate"
      )
      expect(client).to receive(:create_instance).with(
        :min_count => 1, :max_count => 1, :instance_initiated_shutdown_behavior => "terminate"
      )
      driver.submit_server
    end
  end

  describe "#submit_spot" do
    let(:state) { {} }
    let(:response) do
      { :spot_instance_requests => [{ :spot_instance_request_id => "id" }] }
    end

    before do
      expect(driver).to receive(:instance).at_least(:once).and_return(instance)
      allow(Time).to receive(:now).and_return(Time.now)
    end

    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return({})
      expect(actual_client).to receive(:request_spot_instances).with(
        :spot_price => "",
        :launch_specification => {},
        :valid_until => Time.now + (config[:retryable_tries] * config[:retryable_sleep]),
        :block_duration_minutes => 60
      ).and_return(response)
      expect(actual_client).to receive(:wait_until)
      expect(client).to receive(:get_instance_from_spot_request).with("id")
      driver.submit_spot(state)
      expect(state).to eq(:spot_request_id => "id")
    end
  end

  describe "#tag_server" do
    context "with no tags specified" do
      it "does not raise" do
        config[:tags] = nil
        expect { driver.tag_server(server) }.not_to raise_error
      end
    end

    context "with standard string tags" do
      it "tags the server" do
        config[:tags] = { :key1 => "value1", :key2 => "value2" }
        expect(server).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "value2" },
          ]
        )
        driver.tag_server(server)
      end
    end

    context "with a tag that includes a Integer value" do
      it "tags the server" do
        config[:tags] = { :key1 => "value1", :key2 => 1 }
        expect(server).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "1" },
          ]
        )
        driver.tag_server(server)
      end
    end

    context "with a tag that includes a Nil value" do
      it "tags the server" do
        config[:tags] = { :key1 => "value1", :key2 => nil }
        expect(server).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "" },
          ]
        )
        driver.tag_server(server)
      end
    end
  end

  describe "#tag_volumes" do
    let(:volume) { double("aws volume resource") }
    before do
      allow(server).to receive(:volumes).and_return([volume])
    end
    context "with standard string tags" do
      it "tags the instance volumes" do
        config[:tags] = { :key1 => "value1", :key2 => "value2" }
        expect(volume).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "value2" },
          ]
        )
        driver.tag_volumes(server)
      end
    end

    context "with a tag that includes a Integer value" do
      it "tags the instance volumes" do
        config[:tags] = { :key1 => "value1", :key2 => 2 }
        expect(volume).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "2" },
          ]
        )
        driver.tag_volumes(server)
      end
    end

    context "with a tag that includes a Nil value" do
      it "tags the instance volumes" do
        config[:tags] = { :key1 => "value1", :key2 => nil }
        expect(volume).to receive(:create_tags).with(
          :tags => [
            { :key => :key1, :value => "value1" },
            { :key => :key2, :value => "" },
          ]
        )
        driver.tag_volumes(server)
      end
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
  end

  describe "#wait_until_volumes_ready" do
    let(:aws_instance) { double("aws instance") }
    let(:msg) { "volumes to be ready" }
    let(:volume) { double("aws volume resource") }

    before do
      expect(driver).to receive(:wait_with_destroy).with(server, state, msg).and_yield(aws_instance)
    end
    it "first checks instance existence" do
      expect(aws_instance).to receive(:exists?).and_return(false)
      expect(driver.wait_until_volumes_ready(server, state)).to eq(false)
    end
    it "second, it checks for prescence of described volumes" do
      expect(aws_instance).to receive(:exists?).and_return(true)
      expect(actual_client).to receive_message_chain(:describe_volumes, :volumes, :length
      ).and_return(0)
      expect(aws_instance).to receive(:volumes).and_return([])
      expect(driver.wait_until_volumes_ready(server, state)).to eq(false)
    end
    it "third, it compares the described volumes and instance volumes" do
      expect(aws_instance).to receive(:exists?).and_return(true)
      expect(actual_client).to receive_message_chain(:describe_volumes, :volumes, :length
      ).and_return(2)
      expect(aws_instance).to receive(:volumes).and_return([volume])
      expect(driver.wait_until_volumes_ready(server, state)).to eq(false)
    end
    context "when it exists, and both client and instance agree on volumes" do
      it "returns true" do
        expect(aws_instance).to receive(:exists?).and_return(true)
        expect(actual_client).to receive_message_chain(:describe_volumes, :volumes, :length
        ).and_return(1)
        expect(aws_instance).to receive(:volumes).and_return([volume])
        expect(driver.wait_until_volumes_ready(server, state)).to eq(true)
      end
    end
  end

  describe "#fetch_windows_admin_password" do
    let(:msg) { "to fetch windows admin password" }
    let(:aws_instance) { double("aws instance") }
    let(:server_id) { "server_id" }
    let(:encrypted_password) { "alksdofw" }
    let(:data) { double("data", :password_data => encrypted_password) }
    let(:password) { "password" }
    let(:transport) { { :ssh_key => "foo" } }

    before do
      state[:server_id] = server_id
      expect(driver).to receive(:wait_with_destroy).with(server, state, msg).and_yield(aws_instance)
    end

    after do
      expect(state[:password]).to eq(password)
    end

    it "fetches and decrypts the windows password" do
      expect(server).to receive_message_chain("client.get_password_data").with(
        :instance_id => server_id
      ).and_return(data)
      expect(server).to receive(:decrypt_windows_password).
        with(File.expand_path("foo")).
        and_return(password)
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
      expect(server).to receive(:wait_until).and_raise(::Aws::Waiters::Errors::WaiterFailed)
      expect(driver).to receive(:destroy).with(state)
      expect(driver).to receive(:error).with(/#{msg}/)
      expect do
        driver.wait_with_destroy(server, state, msg, &given_block)
      end.to raise_error(::Aws::Waiters::Errors::WaiterFailed)
    end
  end

  describe "#create" do
    let(:server) { double("aws server object", :id => id, :image_id => "ami-3f807145") }
    let(:id) { "i-12345" }

    it "returns if the instance is already created" do
      state[:server_id] = id
      expect(driver.create(state)).to eq(nil)
    end

    image_data = Aws::EC2::Types::Image.new(:root_device_type => "ebs")
    ec2_stub = Aws::EC2::Types::DescribeImagesResult.new
    ec2_stub.images = [image_data]

    shared_examples "common create" do
      it "successfully creates and tags the instance" do
        expect(server).to receive(:wait_until_exists)
        expect(driver).to receive(:update_username)
        expect(driver).to receive(:tag_server).with(server)
        expect(driver).to receive(:tag_volumes).with(server)
        expect(driver).to receive(:wait_until_volumes_ready).with(server, state)
        expect(driver).to receive(:wait_until_ready).with(server, state)
        allow(actual_client).to receive(:describe_images).with({ :image_ids => [server.image_id] }).and_return(ec2_stub)
        expect(transport).to receive_message_chain("connection.wait_until_ready")
        driver.create(state)
        expect(state[:server_id]).to eq(id)
      end
    end

    context "chef provisioner" do
      let(:provisioner) { double("chef provisioner", :name => "chef_solo") }

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
        expect(driver).to receive(:submit_spot).with(state).and_return(server)
      end

      include_examples "common create"
    end

    context "instance is not ebs-backed" do
      before do
        ec2_stub.images[0].root_device_type = "instance-store"
      end

      it "does not tag volumes or wait for volumes to be ready" do
        expect(driver).to_not receive(:tag_volumes).with(server)
        expect(driver).to_not receive(:wait_until_volumes_ready).with(server, state)
      end

      after do
        ec2_stub.images[0].root_device_type = "ebs"
      end
    end

    context "instance is a windows machine" do
      before do
        expect(driver).to receive(:windows_os?).and_return(true)
        expect(transport).to receive(:[]).with(:username).and_return("administrator")
        expect(transport).to receive(:[]).with(:password).and_return(nil)
        expect(driver).to receive(:submit_server).and_return(server)
        expect(driver).to receive(:fetch_windows_admin_password).with(server, state)
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
          expect(actual_client).to receive(:create_security_group).with(group_name: /kitchen-/, description: /Test Kitchen for/, vpc_id: "vpc-1").and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5985, to_port: 5985, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
            { ip_protocol: "tcp", from_port: 5986, to_port: 5986, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
          ])
        end

        include_examples "common create"
      end

      context "with a default VPC" do
        before do
          config.delete(:subnet_id)
          expect(actual_client).to receive(:describe_vpcs).with(filters: [{ name: "isDefault", values: ["true"] }]).and_return(double(vpcs: [double(vpc_id: "vpc-1")]))
          expect(actual_client).to receive(:create_security_group).with(group_name: /kitchen-/, description: /Test Kitchen for/, vpc_id: "vpc-1").and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
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
          expect(actual_client).to receive(:create_security_group).with(group_name: /kitchen-/, description: /Test Kitchen for/).and_return(double(group_id: "sg-9876"))
          expect(actual_client).to receive(:authorize_security_group_ingress).with(group_id: "sg-9876", ip_permissions: [
            { ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{ cidr_ip: "0.0.0.0/0" }] },
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

    context "with no key pair configured" do
      before do
        config[:kitchen_root] = "/kitchen"
        config.delete(:aws_ssh_key_id)
        expect(driver).to receive(:submit_server).and_return(server)
        allow(instance).to receive(:name).and_return("instance_name")

        expect(actual_client).to receive(:create_key_pair).with(key_name: /kitchen-/).and_return(double(key_name: "kitchen-asdf", key_material: "RSA PRIVATE KEY"))
        fake_fd = double()
        fake_file = double()
        allow(File).to receive(:sysopen).and_call_original
        expect(File).to receive(:sysopen).with("/kitchen/.kitchen/instance_name.pem", kind_of(Numeric), kind_of(Numeric)).and_return(fake_fd)
        allow(File).to receive(:open).and_call_original
        expect(File).to receive(:open).with(fake_fd).and_yield(fake_file)
        expect(fake_file).to receive(:write).with("RSA PRIVATE KEY")
      end

      include_examples "common create"
    end

  end

  describe "#destroy" do
    context "when state[:server_id] is nil" do
      it "returns nil" do
        expect(driver.destroy(state)).to eq(nil)
      end
    end

    context "when state has a normal server_id" do
      let(:state) { { :server_id => "id", :hostname => "name" } }

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

    context "when state has a spot request" do
      let(:state) { { :server_id => "id", :hostname => "name", :spot_request_id => "spot" } }

      it "destroys the server" do
        expect(client).to receive(:get_instance).with("id").and_return(server)
        expect(instance).to receive_message_chain("transport.connection.close")
        expect(server).to receive(:terminate)
        expect(actual_client).to receive(:cancel_spot_instance_requests).with(
          :spot_instance_request_ids => ["spot"]
        )
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
