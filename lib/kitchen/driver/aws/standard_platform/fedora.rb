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

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "fedora"
          end

          # EC2 image filters that select Fedora Cloud Base images.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => "125523088429",
              "name" => version ? "Fedora-Cloud-Base-#{version}-*" : "Fedora-Cloud-Base-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [Fedora, nil] a platform when the image is Fedora, otherwise nil
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
