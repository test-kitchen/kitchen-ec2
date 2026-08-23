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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::MacOS do
  it_behaves_like "a standard platform",
    registered_as: %w{macos},
    platform_name: "macos",
    username: "ec2-user",
    search_without_version: { "owner-id" => "100343932686", "name" => "amzn-ec2-macos-*" },
    version: "14",
    search_with_version: { "owner-id" => "100343932686", "name" => "amzn-ec2-macos-14*" },
    detects_image_named: "amzn-ec2-macos-14.5-20240710-201115",
    detected_version: "14.5",
    ignores_image_named: "amzn2-ami-hvm-2.0.20240412.0-x86_64-gp2",
    architecture_filter: "arm64_mac"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  describe "#image_search" do
    it "translates arm64 into EC2's arm64_mac architecture" do
      platform = described_class.new(driver, "macos", nil, "arm64")
      expect(platform.image_search["architecture"]).to eq("arm64_mac")
    end

    it "passes x86_64 through unchanged" do
      platform = described_class.new(driver, "macos", nil, "x86_64")
      expect(platform.image_search["architecture"]).to eq("x86_64")
    end

    # The versioned and unversioned searches must share the "amzn-ec2-macos"
    # prefix that `.from_image` matches on. They did not always: an unversioned
    # search once looked for "amzn2-ec2-macos-*", which matches no real AMI.
    it "uses the same name prefix with and without a version" do
      expect(described_class.new(driver, "macos", nil, nil).image_search["name"])
        .to eq("amzn-ec2-macos-*")
      expect(described_class.new(driver, "macos", "14", nil).image_search["name"])
        .to eq("amzn-ec2-macos-14*")
    end

    # A search whose results the platform cannot then recognize would leave
    # `actual_platform` nil and lose the default username.
    it "finds images that .from_image can detect" do
      image = build_image(name: "amzn-ec2-macos-14.5-20240710-201115")
      pattern = described_class.new(driver, "macos", nil, nil).image_search["name"]

      expect(File.fnmatch(pattern, image.name)).to be(true)
      expect(described_class.from_image(driver, image)).to be_an_instance_of(described_class)
    end
  end
end
