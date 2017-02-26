require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/Cloud_Guide/ch02.html#id697643
        class Fedora < StandardPlatform
          StandardPlatform.platforms["fedora"] = self

          def username
            "fedora"
          end

          def image_search
            search = {
              "owner-id" => "125523088429",
              "name" => version ? "Fedora-Cloud-Base-#{version}-*" : "Fedora-Cloud-Base-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /fedora/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "fedora", (Regexp.last_match || [])[1], image.architecture)
            end
          end
        end
      end
    end
  end
end
