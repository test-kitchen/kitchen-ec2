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

require "kitchen/driver/aws/client"
require "climate_control"

describe Kitchen::Driver::Aws::Client do

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
          "test-profile",
          "http_proxy",
          999,
          false
        )
      end
      it "Sets the AWS config" do
        client
        expect(Aws.config[:region]).to eq("us-west-1")
        expect(Aws.config[:profile]).to eq("test-profile")
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
end
