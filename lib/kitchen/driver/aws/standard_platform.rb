module Kitchen
  module Driver
    class Aws
      # Useful reference for platform AMIs:
      # https://alestic.com/2014/01/ec2-ssh-username/
      class StandardPlatform
        def initialize(driver, name, version, architecture)
          @driver = driver
          @name = name
          @version = version
          @architecture = architecture
        end

        attr_reader :driver
        attr_reader :name
        attr_reader :version
        attr_reader :architecture

        #
        # Find the best matching image for the given image search
        #
        def find_image(image_search)
          driver.debug("Searching for images matching #{image_search} ...")
          # Convert to ec2 search format (pairs of name+values)
          filters = image_search.map do |key, value|
            { name: key.to_s, values: Array(value).map { |v| v.to_s } }
          end

          # We prefer most recent first
          images = driver.ec2.resource.images(:filters => filters)
          # P6: We prefer more recent images over older ones
          images = images.sort_by { |image| image.creation_date }.reverse
          # P5: We prefer x86_64 over i386 (if available)
          images = prefer(images) { |image| image.architecture == :x86_64 }
          # P4: We prefer gp2 (SSD) (if available)
          images = prefer(images) { |image| image.block_device_mappings.any? { |b| b.device_name == image.root_device_name && b.ebs && b.ebs.volume_type == "gp2" } }
          # P3: We prefer ebs over instance_store (if available)
          images = prefer(images) { |image| image.root_device_type == "ebs" }
          # P2: We prefer hvm (the modern standard)
          images = prefer(images) { |image| image.virtualization_type == "hvm" }
          # P1: We prefer the latest version over anything else
          images = sort_by_version(images)
          if images.empty?
            driver.error("Search returned 0 images.")
          else
            driver.debug("Search returned #{images.size} images:")
            images.each do |image|
              root_device = image.block_device_mappings.find { |b| b.device_name == image.root_device_name }
              platform = self.class.from_image(driver, image)
              if platform
                driver.debug("- #{image.name}: Detected #{platform}. Virtualization: #{image.virtualization_type}, Storage: #{image.root_device_type}#{(root_device && root_device.ebs) ? " #{root_device.ebs.volume_type}" : ""}, Created: #{image.creation_date}")
              else
                driver.debug("- #{image.name}: no platform detected. Virtualization: #{image.virtualization_type}, Storage: #{image.root_device_type}#{(root_device && root_device.ebs) ? " #{root_device.ebs.volume_type}" : ""}, Created: #{image.creation_date}")
              end
            end
          end

          # Grab the best match
          images.first && images.first.id
        end

        def self.platforms
          @platforms ||= {}
        end

        def sort_by_version(images)
          # 7.1 -> [ img1, img2, img3 ]
          # 6 -> [ img4, img5 ]
          # ...
          images.group_by { |image| platform = self.class.from_image(driver, image); platform ? platform.version : nil }.
          # sorted by version and flattened
                 sort_by { |k,v| k ? k.to_f : nil }.reverse.map { |k,v| v }.flatten(1)
        end

        def to_s
          "#{name}#{version ? " #{version}" : ""}#{architecture ? " #{architecture}" : ""}"
        end

        # Not supported yet: aix mac_os_x nexus solaris

        ARCHITECTURE = %w(x86_64 i386 i86pc sun4v powerpc)

        def self.from_platform_string(driver, platform_string)
          platform, version, architecture = parse_platform_string(platform_string)
          if platform && platforms[platform]
            platforms[platform].new(driver, platform, version, architecture)
          end
        end

        def self.from_image(driver, image)
          platforms.each_value do |platform|
            result = platform.from_image(driver, image)
            return result if result
          end
          nil
        end

        protected

        def prefer(images, &block)
          # Put the matching ones *before* the non-matching ones.
          matching, non_matching = images.partition(&block)
          matching + non_matching
        end

        private

        def self.parse_platform_string(platform_string)
          platform, version = platform_string.split("-", 2)

          # If the right side is a valid architecture, use it as such
          # i.e. debian-i386 or windows-server-2012r2-i386
          if version && ARCHITECTURE.include?(version.split("-")[-1])
            # server-2012r2-i386 -> server-2012r2, -, i386
            version, _dash, architecture = version.rpartition("-")
            version = nil if version == ""
          end

          [ platform, version, architecture ]
        end
      end
    end
  end
end
