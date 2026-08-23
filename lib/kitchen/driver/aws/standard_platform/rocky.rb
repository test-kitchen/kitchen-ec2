#
# Copyright:: 2023, Jared Kauppila
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
        # Rocky Linux images published by the Rocky Enterprise Software
        # Foundation.
        #
        # @see https://rockylinux.org/cloud-images
        class Rocky < StandardPlatform
          StandardPlatform.platforms["rocky"] = self
          StandardPlatform.platforms["rockylinux"] = self

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "rocky"
          end

          # EC2 image filters that select Rocky Linux images published by the Rocky project.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => "792107900819",
              "name" => version ? "Rocky-#{version}-*" : "Rocky-*",
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
          # @return [Rocky, nil] a platform when the image is Rocky Linux, otherwise nil
          def self.from_image(driver, image)
            return unless /Rocky-/i.match?(image.name)

            # `(\.\d+)?`, not `(\.\d+[\.\d])?`: the character class matched the
            # separator that follows the minor version, capturing it into the
            # version string ("2018.03.") and failing outright when the minor
            # version was followed by anything but a dot or digit.
            image.name =~ /\b(\d+(\.\d+)?)/i
            new(driver, "rocky", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
