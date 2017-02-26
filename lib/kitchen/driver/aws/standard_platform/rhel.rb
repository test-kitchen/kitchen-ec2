require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://aws.amazon.com/blogs/aws/now-available-red-hat-enterprise-linux-64-amis/
        class El < StandardPlatform
          StandardPlatform.platforms["rhel"] = self
          StandardPlatform.platforms["el"] = self

          def initialize(driver, _name, version, architecture)
            # rhel = el
            super(driver, "rhel", version, architecture)
          end

          def username
            (version && version.to_f < 6.4) ? "root" : "ec2-user"
          end

          def image_search
            search = {
              "owner-id" => "309956199498",
              "name" => "RHEL-#{version}*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /rhel/i
              image.name =~ /\b(\d+(\.\d+)?)/i
              new(driver, "rhel", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
