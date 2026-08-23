#
# Copyright:: 2016-2018, Chef Software, Inc.
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

require_relative "../standard_platform"

module Kitchen
  module Driver
    class Aws
      class StandardPlatform
        # https://wiki.debian.org/Cloud/AmazonEC2Image
        class Debian < StandardPlatform
          StandardPlatform.platforms["debian"] = self

          # Debian release numbers to their codenames, newest first.
          #
          # The order matters: the first entry is the newest known release and
          # is what an unversioned Debian platform resolves to.
          #
          # @return [Hash{Integer => String}]
          DEBIAN_CODENAMES = {
            13 => "trixie",
            12 => "bookworm",
            11 => "bullseye",
            10 => "buster",
            9 => "stretch",
            8 => "jessie",
            7 => "wheezy",
            6 => "squeeze",
          }.freeze

          # The account EC2 creates on this platform's official AMIs.
          #
          # Debian uses "admin" rather than the "ec2-user" or distribution-named
          # account most other platforms create.
          #
          # @return [String] the default SSH username
          def username
            "admin"
          end

          # The Debian release codename for the requested version.
          #
          # Only the major version selects a codename, so a more precise version
          # such as "12.5" is truncated, with a warning that the extra precision
          # is being discarded. With no version at all, the newest known release
          # is used.
          #
          # @return [String, nil] the codename, or nil for an unknown version
          def codename
            v = version
            # Warn only when truncating to the major version actually discards
            # something. Comparing string forms keeps a version that arrived as
            # an Integer from warning about itself.
            if v && v.to_s != v.to_i.to_s
              warn("WARN: Debian version #{version} specified, but searching for #{version.to_i} instead.")
            end
            v ? DEBIAN_CODENAMES[v.to_i] : DEBIAN_CODENAMES.values.first
          end

          # EC2 image filters that select Debian cloud images.
          #
          # A filter is added for {StandardPlatform#architecture} only when one was
          # requested, so that an unspecified architecture matches any of them.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the value
          #   or values it must match
          # @see StandardPlatform#find_image
          def image_search
            search = {}

            # The Debian AWS owner ID changed for releases 10 and onwards
            # See https://wiki.debian.org/Amazon/EC2/HowTo/awscli
            if version.nil?
              search["owner-id"] = "136693071363"
              search["name"] = "debian-#{DEBIAN_CODENAMES.keys.first}-*"
            elsif version.to_i >= 10
              search["owner-id"] = "136693071363"
              search["name"] = "debian-#{version.to_i}-*"
            else
              search["owner-id"] = "379101102735"
              search["name"] = "debian-#{codename}-*"
            end

            search["architecture"] = architecture if architecture

            search
          end

          # Sort images newest release first, keeping backports images last.
          #
          # Debian publishes a backports image alongside each release, from the
          # same account and under the same "debian-<release>-" prefix,
          # differing only by the word "backports" in the name:
          #
          #     debian-12-backports-amd64-20260821-2577
          #     debian-12-amd64-20260821-2577
          #
          # It runs the backports kernel rather than the release's own -- 6.12
          # against 6.1 for Debian 12 -- and is often published minutes after
          # its plain counterpart, so a tie broken on creation date handed
          # every Debian platform the backports image.
          #
          # This is a preference rather than a filter, so a release with only
          # backports images published is still selectable.
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, newest release first
          def sort_by_version(images)
            prefer(super) { |image| !image.name.include?("backports") }
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [Debian, nil] a platform when the image is Debian, otherwise nil
          def self.from_image(driver, image)
            return unless /debian/i.match?(image.name)

            image.name =~ /\b(\d+|#{DEBIAN_CODENAMES.values.join("|")})\b/i
            version = (Regexp.last_match || [])[1]
            if version&.to_i&.zero?
              # `to_s`, so that a codename-derived version is the same type as a
              # version read straight out of the image name. Callers compare and
              # display these without caring which path produced them.
              version = DEBIAN_CODENAMES.find do |_v, codename|
                codename == version.downcase
              end&.first&.to_s
            end
            new(driver, "debian", version, image.architecture)
          end
        end
      end
    end
  end
end
