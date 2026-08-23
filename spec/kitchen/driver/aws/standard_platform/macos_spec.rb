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
    search_without_version: { "owner-id" => "628277914472", "name" => "amzn-ec2-macos-*" },
    version: "14",
    search_with_version: { "owner-id" => "628277914472", "name" => "amzn-ec2-macos-14*" },
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

    it "translates x86_64 into EC2's x86_64_mac architecture" do
      platform = described_class.new(driver, "macos", nil, "x86_64")
      expect(platform.image_search["architecture"]).to eq("x86_64_mac")
    end

    # Every Mac AMI reports one of EC2's "_mac" architectures, so a search
    # carrying a bare "x86_64" or "arm64" matches nothing. This was the second
    # half of the bug that made `macos` unusable: correcting the owner alone
    # still left `macos-x86_64` finding zero images.
    it "searches for architectures EC2 actually reports on Mac images" do
      %w{arm64 x86_64}.each do |requested|
        platform = described_class.new(driver, "macos", nil, requested)
        expect(platform.image_search["architecture"]).to end_with("_mac")
      end
    end

    it "passes an architecture it does not know through unchanged" do
      platform = described_class.new(driver, "macos", nil, "arm64_mac")
      expect(platform.image_search["architecture"]).to eq("arm64_mac")
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

    # The owner is the whole search: an owner that publishes nothing returns
    # zero images no matter how well the name pattern is written. Account
    # 100343932686 owns no AMIs in any region, and searching it made every
    # `macos` run fail with "Neither image_id nor an image_search specified".
    it "searches the account Amazon actually publishes Mac images from" do
      expect(described_class::MACOS_OWNER_ID).to eq("628277914472")
      expect(described_class.new(driver, "macos", nil, nil).image_search["owner-id"])
        .to eq("628277914472")
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
