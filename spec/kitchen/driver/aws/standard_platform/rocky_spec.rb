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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Rocky do
  it_behaves_like "a standard platform",
    registered_as: %w{rocky rockylinux},
    platform_name: "rocky",
    username: "rocky",
    search_without_version: { "owner-id" => "792107900819", "name" => "Rocky-*" },
    version: "9",
    search_with_version: { "owner-id" => "792107900819", "name" => "Rocky-9-*" },
    detects_image_named: "Rocky-9-EC2-Base-9.4-20240509.0.x86_64",
    detected_version: "9",
    ignores_image_named: "AlmaLinux OS 9.4.20240805 x86_64"
end
