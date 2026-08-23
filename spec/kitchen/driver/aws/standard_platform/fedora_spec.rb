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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Fedora do
  it_behaves_like "a standard platform",
    registered_as: %w{fedora},
    platform_name: "fedora",
    username: "fedora",
    search_without_version: { "owner-id" => "125523088429", "name" => "Fedora-Cloud-Base-*" },
    version: "40",
    search_with_version: {
      "owner-id" => "125523088429",
      "name" => ["Fedora-Cloud-Base-AmazonEC2.*-40-*", "Fedora-Cloud-Base-40-*"],
    },
    detects_image_named: "Fedora-Cloud-Base-40-1.14.x86_64-hvm-us-west-2-gp3-0",
    detected_version: "40",
    ignores_image_named: "AlmaLinux OS 9.4.20240805 x86_64"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  def platform_for(version)
    described_class.new(driver, "fedora", version, nil)
  end

  describe ".from_image" do
    # Fedora moved to a name that leads with the image target
    # ("AmazonEC2") and the architecture, putting the release number after
    # them instead of directly after "Fedora-Cloud-Base-".
    it "reads the release out of the current image naming scheme" do
      image = build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-42-20250415.0")

      expect(described_class.from_image(driver, image).version).to eq("42")
    end
  end

  describe "#sort_by_version" do
    # Fedora publishes Rawhide, ELN and Prerelease images from the same
    # account and under the same name prefix as its releases. Their names
    # carry no release number, so the version parsed out of them is the
    # build date -- a number far larger than any real release, which would
    # otherwise sort them to the front and hand every `fedora` platform a
    # development build.
    it "pushes development streams behind released versions" do
      images = [
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-Rawhide-20250820.0"),
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-ELN-20250820.0"),
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-43-Prerelease-20250820.0"),
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-42-20250415.0"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to eq("Fedora-Cloud-Base-AmazonEC2.x86_64-42-20250415.0")
    end

    it "prefers the newest release when several are published" do
      images = [
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-41-20250415.0"),
        build_image(name: "Fedora-Cloud-Base-AmazonEC2.x86_64-42-20250415.0"),
      ]

      sorted = platform_for(nil).sort_by_version(images)

      expect(sorted.first.name).to include("-42-")
    end
  end
end
