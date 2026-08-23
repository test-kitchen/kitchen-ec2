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
        # https://wiki.centos.org/Cloud/AWS
        class Centos < StandardPlatform
          StandardPlatform.platforms["centos"] = self

          # The AWS account CentOS publishes its images under. Releases from 8
          # onwards are published directly rather than through the AWS
          # Marketplace, so images are found by owner rather than by product.
          #
          # @return [String]
          CENTOS_OWNER_ID = "125523088429".freeze

          # The account EC2 creates on this platform's official AMIs.
          #
          # CentOS 8 and earlier ship a "centos" account; Stream 9 moved to the
          # "ec2-user" convention used by the other EL-family distributions.
          #
          # @return [String] the default SSH username
          def username
            version && version.to_f < 9.0 ? "centos" : "ec2-user"
          end

          # EC2 image filters that select CentOS Linux and CentOS Stream images.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            # Version 8+ are published directly, not to the AWS marketplace. Use OWNER ID.
            search = {
              "owner-id" => CENTOS_OWNER_ID,
              "name" => ["CentOS #{version}*", "CentOS-#{version}*-GA-*", "CentOS Linux #{version}*", "CentOS Stream #{version}*"],
            }

            search["architecture"] = architecture if architecture
            search
          end

          # Sort images newest release first.
          #
          # CentOS mixes bare majors ("CentOS Stream 9") with dotted releases
          # ("CentOS 7.9"). A bare major is scored as ".999" so that Stream 9
          # ranks above 9.0 while still ranking below 10.
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, newest release first
          def sort_by_version(images)
            # 7.1 -> [ img1, img2, img3 ]
            # 6 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).version }
              .sort_by { |k, _v| (k && k.include?(".") ? k.to_f : "#{k}.999".to_f) }
              .reverse.flat_map { |_k, v| v }
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [Centos, nil] a platform when the image is CentOS, otherwise nil
          def self.from_image(driver, image)
            return unless /centos/i.match?(image.name)

            image.name =~ /\b(\d+(\.\d+)?)\b/i
            new(driver, "centos", (Regexp.last_match || [])[1], image.architecture)
          end
        end
      end
    end
  end
end
