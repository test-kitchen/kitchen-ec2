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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Centos do
  it_behaves_like "a standard platform",
    registered_as: %w{centos},
    platform_name: "centos",
    username: "ec2-user",
    search_without_version: {
      "owner-id" => "125523088429",
      "name" => ["CentOS *", "CentOS-*-GA-*", "CentOS Linux *", "CentOS Stream *"],
    },
    version: "9",
    search_with_version: {
      "owner-id" => "125523088429",
      "name" => ["CentOS 9*", "CentOS-9*-GA-*", "CentOS Linux 9*", "CentOS Stream 9*"],
    },
    detects_image_named: "CentOS Stream 9 x86_64 20240701",
    detected_version: "9",
    ignores_image_named: "Rocky-9-EC2-Base-9.4-20240509.0.x86_64"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  def platform_for(version)
    described_class.new(driver, "centos", version, nil)
  end

  describe "#username" do
    # CentOS 8 and earlier ship a "centos" user; Stream 9 moved to "ec2-user".
    it "is centos below version 9" do
      expect(platform_for("7").username).to eq("centos")
      expect(platform_for("8").username).to eq("centos")
    end

    it "is ec2-user from version 9 onwards" do
      expect(platform_for("9").username).to eq("ec2-user")
      expect(platform_for("10").username).to eq("ec2-user")
    end

    it "is ec2-user when no version is known" do
      expect(platform_for(nil).username).to eq("ec2-user")
    end
  end

  describe "#sort_by_version" do
    # CentOS mixes bare majors ("CentOS Stream 9") with dotted versions
    # ("CentOS 7.9"). A bare major is treated as ".999" so that Stream 9 sorts
    # above 9.0, and every major still sorts above the one below it.
    it "sorts newer majors first" do
      images = [
        build_image(name: "CentOS Linux 7.9 x86_64"),
        build_image(name: "CentOS Stream 9 x86_64"),
        build_image(name: "CentOS Linux 8.4 x86_64"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.map(&:name)).to eq([
        "CentOS Stream 9 x86_64",
        "CentOS Linux 8.4 x86_64",
        "CentOS Linux 7.9 x86_64",
      ])
    end

    it "ranks a bare major above a dotted release of the same major" do
      images = [
        build_image(name: "CentOS Linux 9.0 x86_64"),
        build_image(name: "CentOS Stream 9 x86_64"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to eq("CentOS Stream 9 x86_64")
    end
  end
end
