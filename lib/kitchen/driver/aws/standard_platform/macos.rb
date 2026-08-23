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
        # Amazon's macOS images, which run only on dedicated Mac hosts.
        #
        # @see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-macos-instances.html
        class MacOS < StandardPlatform
          StandardPlatform.platforms["macos"] = self

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "ec2-user"
          end

          # The AWS account Amazon publishes its macOS AMIs under.
          #
          # @return [String]
          MACOS_OWNER_ID = "628277914472".freeze

          # EC2's architecture values for Mac instances, keyed by the name the
          # platform string uses.
          #
          # EC2 reports a Mac image's architecture as "x86_64_mac" or
          # "arm64_mac", never the bare "x86_64" or "arm64" every other
          # platform uses, so an unmapped value matches nothing at all.
          #
          # @return [Hash{String => String}]
          MAC_ARCHITECTURES = {
            "arm64" => "arm64_mac",
            "x86_64" => "x86_64_mac",
          }.freeze

          # EC2 image filters that select Amazon's macOS AMIs, which run only on dedicated Mac hosts.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => MACOS_OWNER_ID,
              "name" => version ? "amzn-ec2-macos-#{version}*" : "amzn-ec2-macos-*",
            }
            if architecture
              search["architecture"] = MAC_ARCHITECTURES.fetch(architecture, architecture)
            end
            search
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [MacOS, nil] a platform when the image is macOS, otherwise nil
          def self.from_image(driver, image)
            return unless /amzn-ec2-macos/i.match?(image.name)

            # `(\.\d+)?`, not `(\.\d+[\.\d])?`: the character class matched the
            # separator that follows the minor version, capturing it into the
            # version string ("2018.03.") and failing outright when the minor
            # version was followed by anything but a dot or digit.
            image.name =~ /\b(\d+(\.\d+)?)/i
            new(driver, "macos", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
