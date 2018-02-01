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
        # https://aws.amazon.com/amazon-linux-ami/
        class Amazon < StandardPlatform
          StandardPlatform.platforms["amazon"] = self

          def username
            "ec2-user"
          end

          def image_search
            search = {
              "owner-id" => "137112412989",
              "name" => version ? "amzn-ami-*-#{version}*" : "amzn-ami-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /amzn-ami/i
              image.name =~ /\b(\d+(\.\d+[\.\d])?)/i
              new(driver, "amazon", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
