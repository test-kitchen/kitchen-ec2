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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::El do
  it_behaves_like "a standard platform",
    registered_as: %w{rhel el},
    platform_name: "rhel",
    username: "ec2-user",
    search_without_version: { "owner-id" => "309956199498", "name" => "RHEL-*" },
    version: "9",
    search_with_version: { "owner-id" => "309956199498", "name" => "RHEL-9*" },
    detects_image_named: "RHEL-9.4.0_HVM-20240605-x86_64-82-Hourly2-GP3",
    detected_version: "9.4",
    ignores_image_named: "CentOS Stream 9 x86_64 20240701"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  def platform_for(version)
    described_class.new(driver, "el", version, nil)
  end

  describe "#initialize" do
    # "el" and "rhel" are registered to the same class; instances normalize to
    # "rhel" regardless of which name the user wrote in their kitchen.yml.
    it "reports the name rhel even when built as el" do
      expect(platform_for("9").name).to eq("rhel")
    end
  end

  describe "#username" do
    # RHEL only gained the ec2-user account in 6.4.
    it "is root below version 6.4" do
      expect(platform_for("6.3").username).to eq("root")
      expect(platform_for("5").username).to eq("root")
    end

    it "is ec2-user from version 6.4 onwards" do
      expect(platform_for("6.4").username).to eq("ec2-user")
      expect(platform_for("9").username).to eq("ec2-user")
    end

    it "is ec2-user when no version is known" do
      expect(platform_for(nil).username).to eq("ec2-user")
    end
  end

  describe "#sort_by_version" do
    # The version sort's result used to be discarded -- `super(images)` was
    # called for its return value and then thrown away, with the Beta
    # partition applied to the original, unsorted argument. Both non-Beta
    # here, so only the version sort can order them.
    it "sorts by release, not by the order the images arrive in" do
      images = [
        build_image(name: "RHEL-9.6.0_HVM-20260811-x86_64-0-Hourly2-GP3"),
        build_image(name: "RHEL-10.0.0_HVM-20260812-x86_64-0-Hourly2-GP3"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to include("RHEL-10.0.0")
    end

    it "pushes Beta images behind generally available ones" do
      images = [
        build_image(name: "RHEL-10.0_Beta-20250101-x86_64-0-Hourly2-GP3"),
        build_image(name: "RHEL-9.4.0_HVM-20240605-x86_64-82-Hourly2-GP3"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to include("RHEL-9.4.0_HVM")
      expect(sorted.last.name).to include("_Beta-")
    end
  end
end
