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
        # https://wiki.almalinux.org/cloud/AWS.html
        class Alma < StandardPlatform
          StandardPlatform.platforms["alma"] = self
          StandardPlatform.platforms["almalinux"] = self

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "ec2-user"
          end

          # EC2 image filters that select AlmaLinux OS images published by the AlmaLinux project.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => "764336703387",
              "name" => version ? "AlmaLinux OS #{version}*" : "AlmaLinux OS *",
            }
            search["architecture"] = architecture if architecture
            search
          end

          # Sort images newest release first, keeping Kitten builds last.
          #
          # AlmaLinux Kitten is AlmaLinux's development distribution, published
          # from the same account and under the same "AlmaLinux OS" prefix as
          # the releases. Its name carries no release number, so {.from_image}
          # reads the major straight into the build date: "AlmaLinux OS Kitten
          # 10.20260727.0" yields "10.20260727", a far larger number than the
          # "10.2" of an actual release, which sorts Kitten ahead of
          # everything. A versioned search is unaffected, since "AlmaLinux OS
          # 10*" does not match "AlmaLinux OS Kitten 10*".
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, newest release first
          def sort_by_version(images)
            prefer(super) { |image| !image.name.include?("Kitten") }
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [Alma, nil] a platform when the image is AlmaLinux, otherwise nil
          def self.from_image(driver, image)
            return unless /AlmaLinux OS/i.match?(image.name)

            image.name =~ /\b(\d+(\.\d+)?)\b/i
            new(driver, "alma", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
