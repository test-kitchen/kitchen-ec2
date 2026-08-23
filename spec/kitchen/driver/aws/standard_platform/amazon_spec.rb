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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Amazon do
  it_behaves_like "a standard platform",
    registered_as: %w{amazon},
    platform_name: "amazon",
    username: "ec2-user",
    search_without_version: { "owner-id" => "137112412989", "name" => "amzn-ami-*" },
    version: "2018.03",
    search_with_version: { "owner-id" => "137112412989", "name" => "amzn-ami-*-2018.03*" },
    detects_image_named: "amzn-ami-hvm-2018.03.0.20180811-x86_64-gp2",
    detected_version: "2018.03",
    ignores_image_named: "amzn2-ami-hvm-2.0.20240412.0-x86_64-gp2"

  it "does not claim an Amazon Linux 2 image" do
    image = build_image(name: "amzn2-ami-hvm-2.0.20240412.0-x86_64-gp2")
    expect(described_class.from_image(instance_double(Kitchen::Driver::Ec2), image)).to be_nil
  end
end
