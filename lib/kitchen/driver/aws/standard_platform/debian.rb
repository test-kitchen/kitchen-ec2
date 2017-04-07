require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://wiki.debian.org/Cloud/AmazonEC2Image
        class Debian < StandardPlatform
          StandardPlatform.platforms["debian"] = self

          DEBIAN_CODENAMES = {
            "8" => "jessie",
            "7" => "wheezy",
            "6" => "squeeze",
          }

          def username
            "admin"
          end

          def codename
            version ? DEBIAN_CODENAMES[version] : DEBIAN_CODENAMES.values.first
          end

          def image_search
            search = {
              "owner-id" => "379101102735",
              "name" => "debian-#{codename}-*",
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /debian/i
              image.name =~ /\b(\d+|#{DEBIAN_CODENAMES.values.join("|")})\b/i
              version = (Regexp.last_match || [])[1]
              if version && version.to_i == 0
                version = DEBIAN_CODENAMES.find do |_v, codename|
                  codename == version.downcase
                end.first
              end
              new(driver, "debian", version, image.architecture)
            end
          end
        end
      end
    end
  end
end
