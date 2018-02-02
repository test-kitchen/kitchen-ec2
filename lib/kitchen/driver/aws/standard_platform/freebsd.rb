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
        # http://www.daemonology.net/freebsd-on-ec2/
        class Freebsd < StandardPlatform
          StandardPlatform.platforms["freebsd"] = self

          def username
            "ec2-user"
          end

          def sudo_command
          end

          def image_search
            search = {
              "owner-id" => "118940168514",
              "name" => ["FreeBSD #{version}*-RELEASE*", "FreeBSD/EC2 #{version}*-RELEASE*"],
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /freebsd/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "freebsd", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
