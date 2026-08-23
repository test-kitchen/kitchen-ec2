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

require "kitchen/driver/ec2_version"

RSpec.describe "Kitchen::Driver::EC2_VERSION" do
  subject(:version) { Kitchen::Driver::EC2_VERSION }

  # release-please rewrites this constant, and the gemspec reads it to set the
  # gem version. A malformed value would only surface at publish time.
  it "is a three-part version string" do
    expect(version).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "is frozen" do
    expect(version).to be_frozen
  end

  it "is parseable as a gem version" do
    expect { Gem::Version.new(version) }.not_to raise_error
  end
end
