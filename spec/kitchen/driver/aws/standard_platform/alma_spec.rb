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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Alma do
  it_behaves_like "a standard platform",
    registered_as: %w{alma almalinux},
    platform_name: "alma",
    username: "ec2-user",
    search_without_version: { "owner-id" => "764336703387", "name" => "AlmaLinux OS *" },
    version: "9",
    search_with_version: { "owner-id" => "764336703387", "name" => "AlmaLinux OS 9*" },
    detects_image_named: "AlmaLinux OS 9.4.20240805 x86_64",
    detected_version: "9.4",
    ignores_image_named: "Rocky-9-EC2-Base-9.4-20240509.0.x86_64"

  describe "#sort_by_version" do
    let(:driver) { instance_double(Kitchen::Driver::Ec2) }

    # AlmaLinux Kitten is AlmaLinux's development distribution, published from
    # the same account and under the same "AlmaLinux OS" prefix as the
    # releases. Its name carries no release number, so the version read off it
    # runs the major straight into the build date -- "10.20260727" parses as a
    # far larger number than the "10.2" of an actual release, which sorts
    # Kitten ahead of everything.
    it "pushes Kitten images behind released versions" do
      images = [
        build_image(name: "AlmaLinux OS Kitten 10.20260727.0 x86_64"),
        build_image(name: "AlmaLinux OS 10.2.20260817.0 x86_64"),
      ]

      sorted = described_class.new(driver, "alma", nil, nil).sort_by_version(images)

      expect(sorted.first.name).to eq("AlmaLinux OS 10.2.20260817.0 x86_64")
      expect(sorted.last.name).to include("Kitten")
    end

    it "prefers the newest release among the released versions" do
      images = [
        build_image(name: "AlmaLinux OS 9.8.20260810 x86_64"),
        build_image(name: "AlmaLinux OS 10.2.20260817.0 x86_64"),
      ]

      sorted = described_class.new(driver, "alma", nil, nil).sort_by_version(images)

      expect(sorted.first.name).to include("10.2")
    end
  end
end
