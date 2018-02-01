#
# Copyright:: 2016-2018, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://aws.amazon.com/blogs/aws/now-available-red-hat-enterprise-linux-64-amis/
        class El < StandardPlatform
          StandardPlatform.platforms["rhel"] = self
          StandardPlatform.platforms["el"] = self

          def initialize(driver, _name, version, architecture)
            # rhel = el
            super(driver, "rhel", version, architecture)
          end

          def username
            (version && version.to_f < 6.4) ? "root" : "ec2-user"
          end

          def image_search
            search = {
              "owner-id" => "309956199498",
              "name" => "RHEL-#{version}*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /rhel/i
              image.name =~ /\b(\d+(\.\d+)?)/i
              new(driver, "rhel", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
