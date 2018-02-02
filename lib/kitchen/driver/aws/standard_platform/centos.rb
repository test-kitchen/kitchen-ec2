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
        # https://wiki.centos.org/Cloud/AWS
        class Centos < StandardPlatform
          StandardPlatform.platforms["centos"] = self

          def username
            # Centos 6.x images use root as the username (but the "centos 6"
            # updateable image uses "centos")
            return "root" if version && version.start_with?("6.")
            "centos"
          end

          def image_search
            search = {
              "owner-alias" => "aws-marketplace",
              "name" => ["CentOS Linux #{version}*", "CentOS-#{version}*-GA-*"],
            }
            search["architecture"] = architecture if architecture
            search
          end

          def sort_by_version(images)
            # 7.1 -> [ img1, img2, img3 ]
            # 6 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).version }.
              sort_by { |k, _v| (k && k.include?(".") ? k.to_f : "#{k}.999".to_f) }.
              reverse.flat_map { |_k, v| v }
          end

          def self.from_image(driver, image)
            if image.name =~ /centos/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "centos", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
