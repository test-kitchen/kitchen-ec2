require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://aws.amazon.com/amazon-linux-ami/
        class Amazon < StandardPlatform
          StandardPlatform.platforms["amazon"] = self

          def username
            "ec2-user"
          end

          def image_search
            search = {
              "owner-id" => "137112412989",
              "name" => version ? "amzn-ami-*-#{version}*" : "amzn-ami-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /amzn-ami/i
              image.name =~ /\b(\d+(\.\d+[\.\d])?)/i
              new(driver, "amazon", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
