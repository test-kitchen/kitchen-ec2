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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Freebsd do
  it_behaves_like "a standard platform",
    registered_as: %w{freebsd},
    platform_name: "freebsd",
    username: "ec2-user",
    search_without_version: {
      "owner-id" => "118940168514",
      "name" => ["FreeBSD *-RELEASE*", "FreeBSD/EC2 *-RELEASE*"],
    },
    version: "14.1",
    search_with_version: {
      "owner-id" => "118940168514",
      "name" => ["FreeBSD 14.1*-RELEASE*", "FreeBSD/EC2 14.1*-RELEASE*"],
    },
    detects_image_named: "FreeBSD 14.1-RELEASE-amd64",
    detected_version: "14.1",
    ignores_image_named: "debian-12-amd64-20240717-1811"

  describe "#sort_by_version" do
    let(:driver) { instance_double(Kitchen::Driver::Ec2) }

    def platform_for(version)
      described_class.new(driver, "freebsd", version, nil)
    end

    # FreeBSD publishes several flavors of each release. Only the cloud-init
    # flavor is a general-purpose cloud image: "base" and "small" ship without
    # sudo, so a converge fails on them, and "builder" does not boot to a
    # usable state on a small instance at all.
    it "prefers the cloud-init flavor over the other flavors of a release" do
      images = [
        build_image(name: "FreeBSD 15.1-RELEASE-p2-amd64 builder ZFS"),
        build_image(name: "FreeBSD 15.1-RELEASE-p2-amd64 base UFS"),
        build_image(name: "FreeBSD 15.1-RELEASE-p2-amd64 small UFS"),
        build_image(name: "FreeBSD 15.1-RELEASE-p2-amd64 cloud-init UFS"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to eq("FreeBSD 15.1-RELEASE-p2-amd64 cloud-init UFS")
    end

    it "still prefers the newest release among the cloud-init images" do
      images = [
        build_image(name: "FreeBSD 14.3-RELEASE-amd64 UEFI-PREFERRED cloud-init UFS"),
        build_image(name: "FreeBSD 15.1-RELEASE-amd64 cloud-init UFS"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to include("15.1")
    end

    # Releases old enough to predate the flavored names publish a single image
    # each, which must still be selectable.
    it "leaves a release with no flavored images alone" do
      images = [
        build_image(name: "FreeBSD 13.4-RELEASE-amd64 UEFI-PREFERRED"),
        build_image(name: "FreeBSD 13.5-RELEASE-amd64 UEFI-PREFERRED"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to include("13.5")
    end
  end

  describe "#sudo_command" do
    # FreeBSD images ship without sudo configured for the default user, so the
    # platform deliberately reports no sudo command at all.
    it "is nil, unlike every other platform" do
      platform = described_class.new(instance_double(Kitchen::Driver::Ec2), "freebsd", nil, nil)
      expect(platform.sudo_command).to be_nil
    end
  end
end
