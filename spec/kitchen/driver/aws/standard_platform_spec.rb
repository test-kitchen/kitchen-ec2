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

require "kitchen/driver/aws/standard_platform"
require "kitchen/driver/ec2"

describe Kitchen::Driver::Aws::StandardPlatform do
  let(:klass) { Kitchen::Driver::Aws::StandardPlatform }

  describe "parse_platform_string" do
    let(:platform_string) { "ubuntu-1604-x86_64" }

    it "successfully parses platform, version and architecture" do
      expect(klass.parse_platform_string(platform_string)).to eq(%w{ubuntu 1604 x86_64})
    end

    context "when there is just a platform" do
      let(:platform_string) { "ubuntu" }

      it "successfully parses platform" do
        expect(klass.parse_platform_string(platform_string)).to eq(["ubuntu", nil, nil])
      end
    end

    context "when there is just platform and version" do
      let(:platform_string) { "ubuntu-1604" }

      it "successfully parses platform and version" do
        expect(klass.parse_platform_string(platform_string)).to eq(["ubuntu", "1604", nil])
      end
    end

    context "when there is an unknown architecture" do
      let(:platform_string) { "ubuntu-1604-powerpc" }

      it "successfully parses platform and includes architecture in version" do
        expect(klass.parse_platform_string(platform_string)).to eq(["ubuntu", "1604-powerpc", nil])
      end
    end
  end

  describe "from_platform_string" do
    let(:driver) { instance_double(Kitchen::Driver::Ec2) }
    let(:platform_string) { "ubuntu-1604-x86_64" }

    it "returns an ubuntu StandardPlatform" do
      expect(klass.from_platform_string(driver, platform_string)).to be_instance_of(klass::Ubuntu)
    end
  end

  describe "#sort_images" do
    let(:img1) do
      instance_double(Aws::EC2::Image,
        creation_date: "1543439623",
        architecture: "amd64",
        block_device_mappings: [],
        root_device_type: "other",
        virtualization_type: "other",
        name: "ubuntu")
    end
    let(:img2) do
      instance_double(Aws::EC2::Image,
        creation_date: "1543439623",
        architecture: "x86_64",
        block_device_mappings: [],
        root_device_type: "other",
        virtualization_type: "other",
        name: "ubuntu")
    end
    let(:img3) do
      instance_double(Aws::EC2::Image,
        creation_date: "1543439623",
        architecture: "x86_64",
        block_device_mappings: [],
        root_device_type: "ebs",
        virtualization_type: "other",
        name: "ubuntu")
    end
    let(:img4) do
      instance_double(Aws::EC2::Image,
        creation_date: "1543439623",
        architecture: "x86_64",
        block_device_mappings: [],
        root_device_type: "ebs",
        virtualization_type: "hvm",
        name: "ubuntu")
    end
    let(:images) { [img1, img2, img3, img4] }
    let(:sorted_images) { [img4, img3, img2, img1] }
    let(:standard_platform) { klass.new(nil, nil, nil, nil) }

    it "correctly sorts the images" do
      expect(standard_platform.send(:sort_images, images)).to eq(sorted_images)
    end
  end
end
