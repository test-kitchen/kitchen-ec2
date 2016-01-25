require 'kitchen/driver/aws/platform'

module Kitchen
  module Driver
    class Aws
      class Platform
        # https://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/Cloud_Guide/ch02.html#id697643
        class Fedora < Platform
          Platform.platforms["fedora"] = self

          def username
            "fedora"
          end

          def image_search
            search = {
              "owner-id" => "125523088429",
              "name" => version ? "Fedora-Cloud-Base-#{version}-*" : "Fedora-Cloud-Base-*"
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /fedora/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "fedora", $1, image.architecture)
            end
          end
        end
      end
    end
  end
end
