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
        # https://wiki.centos.org/Cloud/AWS
        class Centos < StandardPlatform
          StandardPlatform.platforms["centos"] = self

          CENTOS_OWNER_ID = "125523088429".freeze
          PRODUCT_CODES = {
            "6" => "6x5jmcajty9edm3f211pqjfn2",
            "7" => "aw0evgkw8e5c1q413zgy5pjce",
            # It appears that v8 is not published to the
            # AWS marketplace and hence does not have a product code
          }.freeze

          # default username for this platform's ami
          # @return [String]
          def username
            # Centos 6.x images use root as the username (but the "centos 6"
            # updateable image uses "centos")
            return "root" if version && version.start_with?("6.")

            "centos"
          end

          def image_search
            # Version 8+ are published directly, not to the AWS marketplace. Use OWNER ID.
            search = {
              "owner-id" => CENTOS_OWNER_ID,
              "name" => ["CentOS #{version}*", "CentOS-#{version}*-GA-*"],
            }

            if version && version.split(".").first.to_i < 8
              # Versions <8 are published to the AWS marketplace and use a different naming convention
              search = {
                "owner-alias" => "aws-marketplace",
                "name" => ["CentOS Linux #{version}*", "CentOS-#{version}*-GA-*"],
              }
              # For versions published to aws-marketplace, additionally filter on product code to
              # avoid non-official AMIs. Can't use CentOS owner ID here, as the owner ID is that of aws marketplace.
              # https://github.com/test-kitchen/kitchen-ec2/issues/456
              PRODUCT_CODES.keys.each do |major_version|
                search["product-code"] = PRODUCT_CODES[major_version] if version.start_with?(major_version)
              end
            end
            search["architecture"] = architecture if architecture
            search
          end

          def sort_by_version(images)
            # 7.1 -> [ img1, img2, img3 ]
            # 6 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).version }
              .sort_by { |k, _v| (k && k.include?(".") ? k.to_f : "#{k}.999".to_f) }
              .reverse.flat_map { |_k, v| v }
          end

          def self.from_image(driver, image)
            if image.name =~ /centos/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "centos", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
