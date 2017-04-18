require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://help.ubuntu.com/community/EC2StartersGuide#Official_Ubuntu_Cloud_Guest_Amazon_Machine_Images_.28AMIs.29
        class Ubuntu < StandardPlatform
          StandardPlatform.platforms["ubuntu"] = self

          def username
            "ubuntu"
          end

          def image_search
            search = {
              "owner-id" => "099720109477",
              "name" => "ubuntu/images/*/ubuntu-*-#{version}*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /ubuntu/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "ubuntu", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
