#
# Copyright:: 2016-2018, Chef Software, Inc.
# Copyright:: 2015-2018, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Kitchen
  module Driver
    class Aws
      #
      # Lets you grab StandardPlatform objects that help search for official
      # AMIs in your region and tell you useful tidbits like usernames.
      #
      # To use these, set your platform name to a supported platform name like:
      #
      # centos
      # rhel
      # fedora
      # freebsd
      # macos
      # ubuntu
      # windows
      #
      # The implementation will select the latest matching version and AMI.
      #
      # You can specify a version and optional architecture as well:
      #
      # windows-2012r2-i386
      # centos-7
      #
      # Useful reference for platform AMIs:
      # https://alestic.com/2014/01/ec2-ssh-username/
      class StandardPlatform
        #
        # Create a new StandardPlatform object.
        #
        # @param driver [Kitchen::Driver::Ec2] The driver.
        # @param name [String] The name of the platform (rhel, centos, etc.)
        # @param version [String] The version of the platform (7.1, 2008sp1, etc.)
        # @param architecture [String] The architecture (i386, x86_64, arm64)
        #
        def initialize(driver, name, version, architecture)
          @driver = driver
          @name = name
          @version = version
          @architecture = architecture
        end

        #
        # The driver.
        #
        # @return [Kitchen::Driver::Ec2]
        #
        attr_reader :driver

        #
        # The name of the platform (e.g. rhel, centos, etc.)
        #
        # @return [String]
        #
        attr_reader :name

        #
        # The version of the platform (e.g. 7.1, 2008sp1, etc.)
        #
        # @return [String]
        #
        attr_reader :version

        #
        # The architecture of the platform, e.g. i386, x86_64
        #
        # @return [String]
        #
        # @see SUPPORTED_ARCHITECTURES
        #
        attr_reader :architecture

        #
        # The list of supported architectures
        #
        SUPPORTED_ARCHITECTURES = %w{x86_64 i386 arm64}.freeze

        #
        # The list of supported ebs volume types
        #
        EBS_VOLUME_TYPES = %w{gp3 gp2}.freeze

        #
        # Find the best matching image for the given image search.
        #
        # The search hash is converted into EC2's filter format, and the results
        # are ranked by {#sort_images} before the best match is taken.
        #
        # @param image_search [Hash{String => String, Array<String>}] EC2 image
        #   filters, keyed by filter name
        # @return [String, nil] the image ID (e.g. "ami-213984723"), or nil when
        #   the search matched nothing
        def find_image(image_search)
          driver.debug("Searching for images matching #{image_search} ...")
          # Convert to ec2 search format (pairs of name+values)
          filters = image_search.map do |key, value|
            { name: key.to_s, values: Array(value).map(&:to_s) }
          end

          # We prefer most recent first
          images = driver.ec2.resource.images(filters:)
          images = sort_images(images)
          show_returned_images(images)

          # Grab the best match
          images.first&.id
        end

        #
        # The list of StandardPlatform objects. StandardPlatforms register
        # themselves with this.
        #
        # @return [Array<Kitchen::Driver::Aws::StandardPlatform>]
        #
        def self.platforms
          @platforms ||= {}
        end

        # A human-readable description of this platform.
        #
        # Version and architecture are omitted when unknown, so an unqualified
        # platform reads as just "ubuntu" rather than "ubuntu  ".
        #
        # @return [String] e.g. "ubuntu 24.04 x86_64"
        def to_s
          "#{name}#{version ? " #{version}" : ""}#{architecture ? " #{architecture}" : ""}"
        end

        #
        # Instantiate a platform from a platform name.
        #
        # @param driver [Kitchen::Driver::Ec2] The driver.
        # @param platform_string [String] The platform string, e.g. "windows",
        #        "ubuntu-7.1", "centos-7-i386"
        #
        # @return [Kitchen::Driver::Aws::StandardPlatform]
        #
        def self.from_platform_string(driver, platform_string)
          platform, version, architecture = parse_platform_string(platform_string)
          return unless platform && platforms[platform]

          platforms[platform].new(driver, platform, version, architecture)
        end

        #
        # Detect platform from an image.
        #
        # @param driver [Kitchen::Driver::Ec2] The driver.
        # @param image [Aws::Ec2::Image] The EC2 Image object.
        #
        # @return [Kitchen::Driver::Aws::StandardPlatform]
        #
        def self.from_image(driver, image)
          platforms.each_value do |platform|
            result = platform.from_image(driver, image)
            return result if result
          end
          nil
        end

        # Split a platform string into its parts.
        #
        # The trailing segment is only treated as an architecture when it is one
        # of {SUPPORTED_ARCHITECTURES}; anything else stays part of the version,
        # so that a typo surfaces as an unmatched version rather than being
        # silently discarded.
        #
        # @param platform_string [String] e.g. "centos-9-x86_64"
        # @return [Array(String, String, String)] the platform name, version and
        #   architecture, any of which except the name may be nil
        def self.parse_platform_string(platform_string)
          platform, version = platform_string.split("-", 2)

          # If the right side is a valid architecture, use it as such
          # i.e. debian-i386 or windows-server-2012r2-i386
          if version && SUPPORTED_ARCHITECTURES.include?(version.split("-")[-1])
            # server-2012r2-i386 -> server-2012r2, -, i386
            version, _dash, architecture = version.rpartition("-")
            version = nil if version == ""
          end

          [platform, version, architecture]
        end

        protected

        #
        # Sort a list of images by their versions, from greatest to least.
        #
        # This MUST perform a stable sort. (Note that `sort` and `sort_by` are
        # not, by default, stable sorts in Ruby.)
        #
        # Used by the default find_image. The default version calls platform_from_image()
        # on each image, and interprets the versions as floats (7 < 7.1 < 8).
        #
        # @param images [Array[Aws::Ec2::Image]] The list of images to sort
        #
        # @return [Array[Aws::Ec2::Image]] A sorted list.
        #
        def sort_by_version(images)
          # 7.1 -> [ img1, img2, img3 ]
          # 6 -> [ img4, img5 ]
          # ...
          images.group_by do |image|
            platform = self.class.from_image(driver, image)
            platform ? platform.version : nil
          end.sort_by { |k, _v| k ? k.to_f : nil }.reverse.flat_map { |_k, v| v }
        end

        # Not supported yet: aix mac_os_x nexus solaris

        # Move images matching a predicate ahead of those that do not.
        #
        # This is a stable partition rather than a sort, so it expresses a
        # preference without disturbing the ordering established by earlier
        # preferences.
        #
        # @param images [Array<Aws::EC2::Image>] the images to reorder
        # @yieldparam image [Aws::EC2::Image] an image to test
        # @yieldreturn [Boolean] true when the image is preferred
        # @return [Array<Aws::EC2::Image>] preferred images first
        def prefer(images, &block)
          # Put the matching ones *before* the non-matching ones.
          matching, non_matching = images.partition(&block)
          matching + non_matching
        end

        private

        # Rank candidate images, best match first.
        #
        # Preferences are applied from weakest to strongest, each one a stable
        # partition, so the last applied wins: version beats virtualization
        # type, which beats root device type, and so on down to creation date.
        #
        # @param images [Array<Aws::EC2::Image>] the images to rank
        # @return [Array<Aws::EC2::Image>] the images, best match first
        def sort_images(images)
          # P6: We prefer more recent images over older ones
          images = images.sort_by(&:creation_date).reverse
          # P5: We prefer x86_64 over i386 (if available)
          images = prefer(images) { |image| image.architecture == "x86_64" }
          # P4: We prefer (SSD) (if available)
          images = prefer(images) do |image|
            image.block_device_mappings.any? do |b|
              b.device_name == image.root_device_name && b.ebs && EBS_VOLUME_TYPES.any?(b.ebs.volume_type)
            end
          end
          # P3: We prefer ebs over instance_store (if available)
          images = prefer(images) { |image| image.root_device_type == "ebs" }
          # P2: We prefer hvm (the modern standard)
          images = prefer(images) { |image| image.virtualization_type == "hvm" }
          # P1: We prefer the latest version over anything else
          sort_by_version(images)
        end

        # Log the search results, with the platform detected for each image.
        #
        # @param images [Array<Aws::EC2::Image>] the images the search returned
        # @return [void]
        def show_returned_images(images)
          if images.empty?
            driver.error("Search returned 0 images.")
          else
            driver.debug("Search returned #{images.size} images:")
            images.each do |image|
              platform = self.class.from_image(driver, image)
              if platform
                driver.debug("- #{image.name}: Detected #{platform}. #{driver.image_info(image)}")
              else
                driver.debug("- #{image.name}: No platform detected. #{driver.image_info(image)}")
              end
            end
          end
        end
      end
    end
  end
end
