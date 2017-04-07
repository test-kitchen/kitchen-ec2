require "kitchen/driver/aws/standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # http://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/finding-an-ami.html
        class Windows < StandardPlatform
          StandardPlatform.platforms["windows"] = self

          def username
            "administrator"
          end

          # Figure out the right set of names to search for:
          #
          # "windows" -> [nil, nil, nil]
          #   Windows_Server-*-R*_RTM-, Windows_Server-*-R*_SP*-,
          #   Windows_Server-*-RTM-, Windows_Server-*-SP*-,
          #   Windows_Server-*-
          # "windows-2012" -> [2012, 0, nil]
          #   Windows_Server-2012-RTM-, Windows_Server-2012-SP*-
          # "windows-2012r2" -> [2012, 2, nil]
          #   Windows_Server-2012-R2_RTM-, Windows_Server-2012-R2_SP*-
          # "windows-2012sp1" -> [2012, 0, 1]
          #   Windows_Server-2012-SP1-
          # "windows-2012rtm" -> [2012, 0, 0]
          #   Windows_Server-2012-RTM-
          # "windows-2012r2sp1" -> [2012, 2, 1]
          #   Windows_Server-2012-R2_SP1-
          # "windows-2012r2rtm" -> [2012, 2, 0]
          #   Windows_Server-2012-R2_RTM-
          # "windows-2016" -> [2016, 0, nil]
          #   Windows_Server-2016-
          def image_search
            search = {
              "owner-alias" => "amazon",
              "name" => windows_name_filter,
            }
            search["architecture"] = architecture if architecture
            search
          end

          def sort_by_version(images)
            # 2008r2rtm -> [ img1, img2, img3 ]
            # 2012r2sp1 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).windows_version_parts }.
              sort_by { |version, _platform_images| version }.
              reverse.flat_map { |_version, platform_images| platform_images }
          end

          def self.from_image(driver, image)
            if image.name =~ /Windows/i
              # 2008 R2 SP2
              if image.name =~ /(\b\d+)\W*(r\d+)?/i
                major, revision = (Regexp.last_match || [])[1], (Regexp.last_match || [])[2]
                if image.name =~ /(sp\d+|rtm)/i
                  service_pack = (Regexp.last_match || [])[1]
                end
                revision = revision.downcase if revision
                service_pack ||= "rtm"
                service_pack = service_pack.downcase
                version = "#{major}#{revision}#{service_pack}"
              end

              new(driver, "windows", version, image.architecture)
            end
          end

          protected

          # Turn windows version into [ major, revision, service_pack ]
          #
          # nil -> [ nil, nil, nil ]
          # 2012 -> [ 2012, 0, nil ]
          # 2012r2 -> [ 2012, 2, nil ]
          # 2012r2sp4 -> [ 2012, 2, 4 ]
          # 2012sp4 -> [ 2012, 0, 4 ]
          # 2012rtm -> [ 2012, 0, 0 ]
          # 2016 -> [ 2016, 0, nil ]
          def windows_version_parts
            version = self.version
            if version
              # windows-server-* -> windows-*
              if version.split("-", 2)[0] == "server"
                version = version.split("-", 2)[1]
              end

              if version =~ /^(\d+)(r\d+)?(sp\d+|rtm)?$/i
                major, revision, service_pack = Regexp.last_match[1..3]
              end
            end

            if major
              # Get major as an integer (2008 -> 2008, 7 -> 7)
              major = major.to_i

              # Get revision as an integer (no revision -> 0, R1 -> 1).
              revision = revision ? revision[1..-1].to_i : 0

              # Turn service_pack into an integer. rtm = 0, spN = N.
              if service_pack
                service_pack = (service_pack.casecmp("rtm") == 0) ? 0 : service_pack[2..-1].to_i
              end
            end

            [major, revision, service_pack]
          end

          private

          def windows_name_filter # rubocop:disable Metrics/MethodLength
            major, revision, service_pack = windows_version_parts

            if major == 2016
              "Windows_Server-2016-English-Full-Base-*"
            else
              case revision
              when nil
                revision_strings = ["", "R*_"]
              when 0
                revision_strings = [""]
              else
                revision_strings = ["R#{revision}_"]
              end

              case service_pack
              when nil
                revision_strings = revision_strings.flat_map { |r| ["#{r}RTM", "#{r}SP*"] }
              when 0
                revision_strings = revision_strings.map { |r| "#{r}RTM" }
              else
                revision_strings = revision_strings.map { |r| "#{r}SP#{service_pack}" }
              end

              name_filter = revision_strings.map do |r|
                "Windows_Server-#{major || "*"}-#{r}-English-*-Base-*"
              end
              name_filter << "Windows_Server-*-English-Full-Base-*" if major.nil?
              name_filter
            end
          end
        end
      end
    end
  end
end
