#
# Copyright:: 2016-2018, Chef Software, Inc.
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

require_relative "../standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/Cloud_Guide/ch02.html#id697643
        class Fedora < StandardPlatform
          StandardPlatform.platforms["fedora"] = self

          # default username for this platform's ami
          # @return [String]
          def username
            "fedora"
          end

          def image_search
            search = {
              "owner-id" => "125523088429",
              "name" => version ? "Fedora-Cloud-Base-#{version}-*" : "Fedora-Cloud-Base-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            return unless /fedora/i.match?(image.name)

            image.name =~ /\b(\d+(\.\d+)?)\b/i
            new(driver, "fedora", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
