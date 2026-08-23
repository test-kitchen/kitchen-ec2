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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Ubuntu do
  it_behaves_like "a standard platform",
    registered_as: %w{ubuntu},
    platform_name: "ubuntu",
    username: "ubuntu",
    search_without_version: { "owner-id" => "099720109477", "name" => "ubuntu/images/*/ubuntu-*-*" },
    version: "24.04",
    search_with_version: { "owner-id" => "099720109477", "name" => "ubuntu/images/*/ubuntu-*-24.04*" },
    detects_image_named: "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801",
    detected_version: "24.04",
    ignores_image_named: "debian-12-amd64-20240717-1811"
end
