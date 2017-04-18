require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://wiki.centos.org/Cloud/AWS
        class Centos < StandardPlatform
          StandardPlatform.platforms["centos"] = self

          def username
            # Centos 6.x images use root as the username (but the "centos 6"
            # updateable image uses "centos")
            return "root" if version && version.start_with?("6.")
            "centos"
          end

          def image_search
            search = {
              "owner-alias" => "aws-marketplace",
              "name" => ["CentOS Linux #{version}*", "CentOS-#{version}*-GA-*"],
            }
            search["architecture"] = architecture if architecture
            search
          end

          def sort_by_version(images)
            # 7.1 -> [ img1, img2, img3 ]
            # 6 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).version }.
              sort_by { |k, _v| (k && k.include?(".") ? k.to_f : "#{k}.999".to_f) }.
              reverse.flat_map { |_k, v| v }
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
