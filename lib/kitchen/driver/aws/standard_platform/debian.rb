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
        # https://wiki.debian.org/Cloud/AmazonEC2Image
        class Debian < StandardPlatform
          StandardPlatform.platforms["debian"] = self

          # 10/11 are listed last since we default to the first item in the hash
          # and 10/11 are not released yet. When they're released move them up
          DEBIAN_CODENAMES = {
            "9" => "stretch",
            "8" => "jessie",
            "7" => "wheezy",
            "6" => "squeeze",
            "11" => "bullseye",
            "10" => "buster",
          }

          def username
            "admin"
          end

          def codename
            version ? DEBIAN_CODENAMES[version] : DEBIAN_CODENAMES.values.first
          end

          def image_search
            search = {
              "owner-id" => "379101102735",
              "name" => "debian-#{codename}-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /debian/i
              image.name =~ /\b(\d+|#{DEBIAN_CODENAMES.values.join("|")})\b/i
              version = (Regexp.last_match || [])[1]
              if version && version.to_i == 0
                version = DEBIAN_CODENAMES.find do |_v, codename|
                  codename == version.downcase
                end.first
              end
              new(driver, "debian", version, image.architecture)
            end
          end
        end
      end
    end
  end
end
