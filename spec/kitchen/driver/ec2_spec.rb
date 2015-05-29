# -*- encoding: utf-8 -*-
#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright (C) 2015, Fletcher Nichol
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
  let(:config)        { { :aws_ssh_key_id => "key", :image_id => "ami-1234567" } }
  let(:platform)      { Kitchen::Platform.new(:name => "fooos-99") }
  let(:suite)         { Kitchen::Suite.new(:name => "suitey") }
  let(:verifier)      { Kitchen::Verifier::Dummy.new }
  let(:provisioner)   { Kitchen::Provisioner::Dummy.new }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:state_file)    { double("state_file") }
  let(:generator)     { instance_double(Kitchen::Driver::Aws::InstanceGenerator) }
  # There is too much name overlap I let creep in - my `client` is actually
  # a wrapper around the actual ec2 client
  let(:actual_client) { double("actual ec2 client") }
  let(:client)        { double(Kitchen::Driver::Aws::Client, :client => actual_client) }
  let(:server) { double("aws server object") }

  let(:driver) { Kitchen::Driver::Ec2.new(config) }

  let(:instance) do
    Kitchen::Instance.new(
      :verifier => verifier,
      :driver => driver,
      :logger => logger,
      :suite => suite,
      :platform => platform,
      :provisioner => provisioner,
      :transport => transport,
      :state_file => state_file
    )
  end

  before do
    allow(Kitchen::Driver::Aws::InstanceGenerator).to receive(:new).and_return(generator)
    allow(Kitchen::Driver::Aws::Client).to receive(:new).and_return(client)
  end

  it "driver api_version is 2" do
    expect(driver.diagnose_plugin[:api_version]).to eq(2)
  end

  it "plugin_version is set to Kitchen::Vagrant::VERSION" do
    expect(driver.diagnose_plugin[:version]).to eq(
      Kitchen::Driver::EC2_VERSION)
  end

  describe "configuration" do
    let(:config) { {} }
    it "requires :aws_ssh_key_id to be provided" do
      expect { driver.finalize_config!(instance) }.to \
        raise_error(Kitchen::UserError, /:aws_ssh_key_id/)
    end

    it "requires :image_id to be provided" do
      config[:aws_ssh_key_id] = "key"
      expect { driver.finalize_config!(instance) }.to \
        raise_error(Kitchen::UserError, /:image_id/)
    end
  end

  describe "#finalize_config!" do
    it "defaults the availability zone if not provided" do
      expect(config[:availability_zone]).to eq(nil)
      driver.finalize_config!(instance)
      expect(config[:availability_zone]).to eq("us-east-1b")
    end
  end

  describe "#hostname" do
    let(:public_dns_name) { nil }
    let(:public_ip_address) { nil }
    let(:private_ip_address) { nil }
    let(:server) {
      double("server",
        :public_dns_name => public_dns_name,
        :public_ip_address => public_ip_address,
        :private_ip_address => private_ip_address
      )
    }

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
    end

    context "private_ip_address is populated" do
      let(:private_ip_address) { "10.0.0.1" }

      it "returns the private_ip_address" do
        expect(driver.hostname(server)).to eq(private_ip_address)
      end

      include_examples "an interface type provided"
    end

    context "public_ip_address is populated" do
      let(:private_ip_address) { "10.0.0.1" }
      let(:public_ip_address) { "127.0.0.1" }

      it "returns the public_ip_address" do
        expect(driver.hostname(server)).to eq(public_ip_address)
      end

      include_examples "an interface type provided"
    end

    context "public_dns_name is populated" do
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
      end
    end
  end

  describe "#submit_server" do
    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return({})
      expect(client).to receive(:create_instance).with(:min_count => 1, :max_count => 1)
      driver.submit_server
    end
  end

  describe "#submit_spot" do
    let(:state) { {} }
    let(:response) {
      { :spot_instance_requests => [{ :spot_instance_request_id => "id" }] }
    }

    it "submits the server request" do
      expect(generator).to receive(:ec2_instance_data).and_return({})
      expect(actual_client).to receive(:request_spot_instances).with(
        :spot_price => "", :launch_specification => {}
      ).and_return(response)
      expect(actual_client).to receive(:wait_until)
      expect(client).to receive(:get_instance_from_spot_request).with("id")
      driver.submit_spot(state)
      expect(state).to eq(:spot_request_id => "id")
    end
  end

  describe "#tag_server" do
    it "tags the server" do
      config[:tags] = { :key1 => :value1, :key2 => :value2 }
      expect(server).to receive(:create_tags).with(
        :tags => [
          { :key => :key1, :value => :value1 },
          { :key => :key2, :value => :value2 }
        ]
      )
      driver.tag_server(server)
    end
  end

  describe "#destroy" do
    context "when state[:server_id] is nil" do
      let(:state) { {} }
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
  end

end
