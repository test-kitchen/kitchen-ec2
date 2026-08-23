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
        # https://aws.amazon.com/blogs/aws/now-available-red-hat-enterprise-linux-64-amis/
        class El < StandardPlatform
          StandardPlatform.platforms["rhel"] = self
          StandardPlatform.platforms["el"] = self

          # Build a Red Hat Enterprise Linux platform.
          #
          # This class is registered under both "rhel" and "el", so the name it
          # was constructed with is discarded and normalized to "rhel".
          #
          # @param driver [Kitchen::Driver::Ec2] the driver
          # @param _name [String] the registered name, ignored
          # @param version [String, nil] the requested version, e.g. "9.4"
          # @param architecture [String, nil] the requested architecture
          def initialize(driver, _name, version, architecture)
            # rhel = el
            super(driver, "rhel", version, architecture)
          end

          # The account EC2 creates on this platform's official AMIs.
          #
          # RHEL only gained the unprivileged "ec2-user" account in 6.4; earlier
          # releases are logged into as root.
          #
          # @return [String] the default SSH username
          def username
            version && version.to_f < 6.4 ? "root" : "ec2-user"
          end

          # EC2 image filters that select Red Hat Enterprise Linux AMIs published by Red Hat.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => "309956199498",
              "name" => "RHEL-#{version}*",
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
          # @return [El, nil] a platform when the image is Red Hat Enterprise Linux, otherwise nil
          def self.from_image(driver, image)
            return unless /rhel/i.match?(image.name)

            image.name =~ /\b(\d+(\.\d+)?)/i
            new(driver, "rhel", (Regexp.last_match || [])[1], image.architecture)
          end

          # Sort images newest release first, preferring generally available
          # releases over betas.
          #
          # A Beta AMI carries a higher version number than the current GA
          # release, so a plain version sort would select it. Betas are pushed
          # to the back after sorting.
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, best match first
          def sort_by_version(images)
            # First do a normal version sort
            super(images)
            # Now sort again, shunning Beta releases.
            prefer(images) { |image| !image.name.match(/_Beta-/i) }
          end
        end
      end
    end
  end
end
