#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Christopher Maier (<cm@chef.io>)
# Author:: Ryan Hass (<rhass@chef.io>)
# Copyright:: Copyright (c) 2017-2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Mixlib
  class Versioning
    class Format
      # Handles partial version strings.
      # -----------------
      # ```text
      # MAJOR
      # MAJOR.MINOR
      # ```
      #
      # EXAMPLES
      # --------
      # ```text
      # 11
      # 11.0
      # ```
      #
      # @author Seth Chisamore (<schisamo@chef.io>)
      # @author Christopher Maier (<cm@chef.io>)
      # @author Ryan Hass (<rhass@chef.io>)
      class PartialSemVer < Format
        #  http://rubular.com/r/NmRSN8vCie
        PARTIAL_REGEX = /^(\d+)\.?(?:(\d*))$/
        # @see Format#parse
        def parse(version_string)
          match = version_string.match(PARTIAL_REGEX) rescue nil

          unless match
            raise Mixlib::Versioning::ParseError, "'#{version_string}' is not a valid #{self.class} version string!"
          end

          @major, @minor = match[1..2]
          @major, @minor, @patch = [@major, @minor, @patch].map(&:to_i)

          # Partial versions do not contain these values, so we just set them to nil.
          @prerelease = nil
          @build      = nil
        end
      end # class Partial
    end # class Format
  end # module Versioning
end # module Mixlib
