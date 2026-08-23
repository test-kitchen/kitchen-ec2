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

  describe "#sudo_command" do
    # FreeBSD images ship without sudo configured for the default user, so the
    # platform deliberately reports no sudo command at all.
    it "is nil, unlike every other platform" do
      platform = described_class.new(instance_double(Kitchen::Driver::Ec2), "freebsd", nil, nil)
      expect(platform.sudo_command).to be_nil
    end
  end
end
