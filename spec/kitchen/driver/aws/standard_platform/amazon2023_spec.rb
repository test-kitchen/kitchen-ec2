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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Amazon2023 do
  it_behaves_like "a standard platform",
    registered_as: %w{amazon2023},
    platform_name: "amazon2023",
    username: "ec2-user",
    search_without_version: { "owner-id" => "137112412989", "name" => "al2023-ami-2023.*" },
    version: "5",
    search_with_version: { "owner-id" => "137112412989", "name" => "al2023-ami-2023.5*" },
    detects_image_named: "al2023-ami-2023.5.20240819.0-kernel-6.1-x86_64",
    detected_version: "2023.5",
    ignores_image_named: "amzn2-ami-hvm-2.0.20240412.0-x86_64-gp2"
end
