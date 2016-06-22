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

require "kitchen/driver/aws/client"
require "climate_control"

describe Kitchen::Driver::Aws::Client do
  describe "::get_credentials" do
    let(:shared) { instance_double(Aws::SharedCredentials) }
    let(:iam)    { instance_double(Aws::InstanceProfileCredentials) }

    # nothing else is set, so we default to this
    it "loads IAM credentials last" do
      env_creds(nil, nil) do
        expect(::Aws::SharedCredentials).to receive(:new).and_return(false)
        expect(Aws::InstanceProfileCredentials).to receive(:new).and_return(iam)
        expect(Kitchen::Driver::Aws::Client.get_credentials("profile", nil, nil, nil)).to eq(iam)
      end
    end

    it "loads shared credentials second to last" do
      env_creds(nil, nil) do
        expect(Aws::SharedCredentials).to \
          receive(:new).with(:profile_name => "profile").and_return(shared)
        expect(Kitchen::Driver::Aws::Client.get_credentials("profile", nil, nil, nil)).to eq(shared)
      end
    end

    it "loads shared credentials third to last" do
      expect(shared).to_not receive(:loadable?)
      env_creds("key_id", "secret") do
        expect(Kitchen::Driver::Aws::Client.get_credentials("profile", nil, nil, nil)).to \
          be_a(Aws::Credentials).and have_attributes(
            :access_key_id => "key_id",
            :secret_access_key => "secret"
          )
      end
    end

    it "loads provided credentials first" do
      expect(shared).to_not receive(:loadable?)
      expect(Kitchen::Driver::Aws::Client.get_credentials("profile", "key3", "value3", nil)).to \
        be_a(Aws::Credentials).and have_attributes(
         :access_key_id => "key3",
         :secret_access_key => "value3",
         :session_token => nil
       )
    end

    it "uses a session token if provided" do
      expect(shared).to_not receive(:loadable?)
      expect(Kitchen::Driver::Aws::Client.get_credentials("profile", "key3", "value3", "t")).to \
        be_a(Aws::Credentials).and have_attributes(
         :access_key_id => "key3",
         :secret_access_key => "value3",
         :session_token => "t"
       )
    end
  end

  let(:client) { Kitchen::Driver::Aws::Client.new("us-west-1") }

  describe "#initialize" do

    it "successfully creates a client" do
      expect(client).to be_a(Kitchen::Driver::Aws::Client)
    end

    it "Sets the AWS config" do
      client
      expect(Aws.config[:region]).to eq("us-west-1")
    end

    context "when provided all optional parameters" do
      let(:client) {
        Kitchen::Driver::Aws::Client.new(
          "us-west-1",
          "profile_name",
          "access_key_id",
          "secret_access_key",
          "session_token",
          "http_proxy",
          999
        )
      }
      let(:creds) { double("creds") }
      it "Sets the AWS config" do
        expect(Kitchen::Driver::Aws::Client).to receive(:get_credentials).and_return(creds)
        client
        expect(Aws.config[:region]).to eq("us-west-1")
        expect(Aws.config[:credentials]).to eq(creds)
        expect(Aws.config[:http_proxy]).to eq("http_proxy")
        expect(Aws.config[:retry_limit]).to eq(999)
      end
    end
  end

  it "returns a client" do
    expect(client.client).to be_a(Aws::EC2::Client)
  end

  it "returns a resource" do
    expect(client.resource).to be_a(Aws::EC2::Resource)
  end

  def env_creds(key_id, secret, &block)
    ClimateControl.modify(
      "AWS_ACCESS_KEY_ID" => key_id,
      "AWS_SECRET_ACCESS_KEY" => secret
    ) do
      block.call
    end
  end
end
