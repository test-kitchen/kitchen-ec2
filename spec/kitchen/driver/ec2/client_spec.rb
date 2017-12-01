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
    let(:config) do
      OpenStruct.new({
        access_key_id: "key3",
        secret_access_key: "value3",
        session_token: nil,
        profile: "profile",
        region: "us-west-1",
        instance_profile_credentials_retries: 1,
      })
    end

    let(:credentials) { double("credentials") }
    let(:chain) { double("chain") }
    let(:assume_role) { instance_double(Aws::AssumeRoleCredentials) }
    let(:sts_client) { instance_double(Aws::STS::Client) }

    it "uses credentials chain" do
      expect(Aws::CredentialProviderChain).to receive(:new).with(config).and_return(chain)
      expect(chain).to receive(:resolve).and_return(credentials)
      expect(Kitchen::Driver::Aws::Client.get_credentials(
        "profile",
        "key3",
        "value3",
        nil,
        "us-west-1"
      )).to eq(credentials)
    end

    it "uses credentials chain + STS AssumeRole" do
      expect(Aws::CredentialProviderChain).to receive(:new).with(config).and_return(chain)
      expect(chain).to receive(:resolve).and_return(credentials)
      expect(Aws::STS::Client).to \
        receive(:new).with(:credentials => credentials, :region => "us-west-1").and_return(sts_client)
      expect(Aws::AssumeRoleCredentials).to \
        receive(:new).with(
          :client => sts_client,
          :role_arn => "role_arn",
          :role_session_name => "role_session_name"
        ).and_return(assume_role)

      expect(Kitchen::Driver::Aws::Client.get_credentials(
        "profile",
        "key3",
        "value3",
        nil,
        "us-west-1",
        :assume_role_arn => "role_arn", :assume_role_session_name => "role_session_name"
      )).to eq(assume_role)
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
      let(:client) do
        Kitchen::Driver::Aws::Client.new(
          "us-west-1",
          "profile_name",
          "access_key_id",
          "secret_access_key",
          "session_token",
          "http_proxy",
          999,
          false
        )
      end
      let(:creds) { double("creds") }
      it "Sets the AWS config" do
        expect(Kitchen::Driver::Aws::Client).to receive(:get_credentials).and_return(creds)
        client
        expect(Aws.config[:region]).to eq("us-west-1")
        expect(Aws.config[:credentials]).to eq(creds)
        expect(Aws.config[:http_proxy]).to eq("http_proxy")
        expect(Aws.config[:retry_limit]).to eq(999)
        expect(Aws.config[:ssl_verify_peer]).to eq(false)
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
      yield
    end
  end
end
