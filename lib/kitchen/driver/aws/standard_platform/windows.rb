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
        # http://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/finding-an-ami.html
        class Windows < StandardPlatform
          StandardPlatform.platforms["windows"] = self

          # The account EC2 creates on this platform's official AMIs.
          #
          # Used as the SSH username when the transport does not specify one.
          #
          # @return [String] the default SSH username
          def username
            "administrator"
          end

          # EC2 image filters that select Amazon's Windows Server AMIs.
          #
          # Windows AMI names encode the release, an optional revision ("R2")
          # and an optional service pack, and the naming scheme changed with
          # Server 2016. The requested version is decomposed by
          # {#windows_version_parts} and turned into whichever set of name
          # patterns can match it:
          #
          #     "windows"          Windows_Server-*-RTM-, -SP*-, -R*_RTM-,
          #                        -R*_SP*-, and Windows_Server-*-Full-Base-*
          #     "windows-2012"     Windows_Server-2012-RTM-, -2012-SP*-
          #     "windows-2012r2"   Windows_Server-2012-R2_RTM-, -R2_SP*-
          #     "windows-2012sp1"  Windows_Server-2012-SP1-
          #     "windows-2012r2sp1" Windows_Server-2012-R2_SP1-
          #     "windows-2016"     Windows_Server-2016-English-Full-Base-*
          #     "windows-2019"     Windows_Server-2019-English-Full-Base-*
          #
          # A filter is added for {StandardPlatform#architecture} only when one
          # was requested, so that an unspecified architecture matches any.
          #
          # @return [Hash{String => String, Array<String>}] filter name to the
          #   value or values it must match
          # @see #windows_name_filter
          # @see StandardPlatform#find_image
          def image_search
            search = {
              "owner-alias" => "amazon",
              "name" => windows_name_filter,
            }
            search["architecture"] = architecture if architecture
            search
          end

          # Sort images newest release first.
          #
          # Windows versions cannot be compared as numbers -- "2012r2" is newer
          # than "2012" but older than "2016" -- so each image is reduced to a
          # [major, revision, service_pack] tuple and those are compared
          # instead.
          #
          # @param images [Array<Aws::EC2::Image>] the images to sort
          # @return [Array<Aws::EC2::Image>] the images, newest release first
          def sort_by_version(images)
            # 2008r2rtm -> [ img1, img2, img3 ]
            # 2012r2sp1 -> [ img4, img5 ]
            # ...
            images.group_by { |image| self.class.from_image(driver, image).windows_version_parts }
              .sort_by { |version, _platform_images| version }
              .reverse.flat_map { |_version, platform_images| platform_images }
          end

          # Detect this platform from an EC2 image.
          #
          # Matching is done on the image name, which is the only reliable signal
          # EC2 exposes about what an AMI actually contains.
          #
          # @param driver [Kitchen::Driver::Ec2] the driver requesting detection
          # @param image [Aws::EC2::Image] the image to inspect
          # @return [Windows, nil] a platform when the image is Windows Server, otherwise nil
          def self.from_image(driver, image)
            return unless /Windows/i.match?(image.name)

            # 2008 R2 SP2
            if image.name =~ /(\b\d+)\W*(r\d+)?/i
              major = (Regexp.last_match || [])[1]
              revision = (Regexp.last_match || [])[2]
              service_pack = (Regexp.last_match || [])[1] if image.name =~ /(sp\d+|rtm)/i
              revision = revision.downcase if revision
              service_pack ||= "rtm"
              service_pack = service_pack.downcase
              version = "#{major}#{revision}#{service_pack}"
            end

            new(driver, "windows", version, image.architecture)
          end

          protected

          # Decompose a Windows version string into comparable parts.
          #
          # A missing revision becomes 0 so that "2012" and "2012r2" order
          # correctly against each other. A missing service pack stays nil,
          # which means "any", while an explicit "rtm" becomes 0.
          #
          #     nil        -> [nil,  nil, nil]
          #     "2012"     -> [2012, 0,   nil]
          #     "2012r2"   -> [2012, 2,   nil]
          #     "2012rtm"  -> [2012, 0,   0]
          #     "2012sp4"  -> [2012, 0,   4]
          #     "2012r2sp4"-> [2012, 2,   4]
          #     "2016"     -> [2016, 0,   nil]
          #
          # A leading "server-" is stripped first, so that a platform named
          # "windows-server-2019" behaves like "windows-2019".
          #
          # @return [Array(Integer, Integer, Integer), Array(nil, nil, nil)]
          #   the major version, revision and service pack
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

          # Build the AMI name patterns for the requested version.
          #
          # @return [String, Array<String>] a single pattern for releases with a
          #   predictable name, otherwise every pattern that could match
          def windows_name_filter
            major, revision, service_pack = windows_version_parts
            if [2025, 2022, 2019, 2016].include?(major)
              "Windows_Server-#{major}-English-Full-Base-*"
            elsif [1709, 1803].include?(major)
              "Windows_Server-#{major}-English-Core-ContainersLatest-*"
            else
              revision_strings = case revision
                                 when nil
                                   ["", "R*_"]
                                 when 0
                                   [""]
                                 else
                                   ["R#{revision}_"]
                                 end

              revision_strings = case service_pack
                                 when nil
                                   revision_strings.flat_map { |r| ["#{r}RTM", "#{r}SP*"] }
                                 when 0
                                   revision_strings.map { |r| "#{r}RTM" }
                                 else
                                   revision_strings.map { |r| "#{r}SP#{service_pack}" }
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
