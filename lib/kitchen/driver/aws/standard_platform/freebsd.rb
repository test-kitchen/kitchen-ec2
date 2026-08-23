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
        # http://www.daemonology.net/freebsd-on-ec2/
        class Freebsd < StandardPlatform
          StandardPlatform.platforms["freebsd"] = self

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "ec2-user"
          end

          # The command used to elevate privileges on this platform.
          #
          # FreeBSD AMIs do not configure sudo for the default account, so this
          # is deliberately nil rather than the usual "sudo".
          #
          # @return [nil] always
          def sudo_command; end

          # EC2 image filters that select FreeBSD RELEASE images.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-id" => "782442783595",
              "name" => ["FreeBSD #{version}*-RELEASE*", "FreeBSD/EC2 #{version}*-RELEASE*"],
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
          # @return [Freebsd, nil] a platform when the image is FreeBSD, otherwise nil
          def self.from_image(driver, image)
            return unless /freebsd/i.match?(image.name)

            image.name =~ /\b(\d+(\.\d+)?)\b/i
            new(driver, "freebsd", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
