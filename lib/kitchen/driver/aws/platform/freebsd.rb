require 'kitchen/driver/aws/platform'

module Kitchen
  module Driver
    class Aws
      class Platform
        # http://www.daemonology.net/freebsd-on-ec2/
        class Freebsd < Platform
          Platform.platforms["freebsd"] = self

          def username
            (version && version.to_f < 9.1) ? "root" : "ec2-user"
          end

          def sudo_command
          end

          def image_search
            search = {
              "owner-id" => "118940168514",
              "name" => [ "FreeBSD #{version}*-RELEASE*", "FreeBSD/EC2 #{version}*-RELEASE*" ]
            }
            search["architecture"] = architecture if architecture
            search
          end

          def self.from_image(driver, image)
            if image.name =~ /freebsd/i
              image.name =~ /\b(\d+(\.\d+)?)\b/i
              new(driver, "freebsd", $1, image.architecture)
            end
          end
        end
      end
    end
  end
end
