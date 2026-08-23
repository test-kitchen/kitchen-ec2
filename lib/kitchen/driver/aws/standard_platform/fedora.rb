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

          # Name fragments marking an image as a development stream rather
          # than a Fedora release: Rawhide (the rolling development branch),
          # ELN (Enterprise Linux Next) and the Prerelease builds published
          # while a release is still stabilising.
          DEVELOPMENT_STREAMS = /-(?:Rawhide|ELN|Prerelease)-/i

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
              "name" => if version
                          # Both naming schemes are searched because the older
                          # one is still present in some regions.
                          ["Fedora-Cloud-Base-AmazonEC2.*-#{version}-*",
                           "Fedora-Cloud-Base-#{version}-*"]
                        else
                          "Fedora-Cloud-Base-*"
                        end,
            }
            search["architecture"] = architecture if architecture
            search
          end

          # Sort images newest release first, keeping development streams last.
          #
          # Fedora publishes Rawhide, ELN and Prerelease images from the same
          # account and under the same "Fedora-Cloud-Base-" prefix as its
          # releases. Those names carry a build date where a release carries a
          # release number, so {.from_image} reads a version like "20250820.0"
          # off them -- larger than any real release, which sorts them to the
          # front. They are pushed to the back afterwards, the same way RHEL
          # handles its Beta images.
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, newest release first
          def sort_by_version(images)
            images = super
            prefer(images) { |image| !DEVELOPMENT_STREAMS.match?(image.name) }
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
