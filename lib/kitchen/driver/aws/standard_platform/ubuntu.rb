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
        # https://help.ubuntu.com/community/EC2StartersGuide#Official_Ubuntu_Cloud_Guest_Amazon_Machine_Images_.28AMIs.29
        class Ubuntu < StandardPlatform
          StandardPlatform.platforms["ubuntu"] = self

          def username
            "ubuntu"
          end

          def image_search
            search = {
              "owner-id" => "099720109477",
              "name" => "ubuntu/images/*/ubuntu-*-#{version}*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /ubuntu/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "ubuntu", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
