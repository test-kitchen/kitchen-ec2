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

require_relative "../standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes.html
        class Alma < StandardPlatform
          StandardPlatform.platforms["alma"] = self
          StandardPlatform.platforms["almalinux"] = self

          # default username for this platform's ami
          # @return [String]
          def username
            "ec2-user"
          end

          def image_search
            search = {
              "owner-id" => "764336703387",
              "name" => version ? "AlmaLinux OS #{version}*" : "AlmaLinux OS *",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if /AlmaLinux OS/i.match?(image.name)
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "alma", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
