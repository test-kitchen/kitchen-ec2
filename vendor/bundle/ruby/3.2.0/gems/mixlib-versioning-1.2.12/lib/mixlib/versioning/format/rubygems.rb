#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Christopher Maier (<cm@chef.io>)
# Copyright:: Copyright (c) 2013-2018 Chef Software, Inc.
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
      # Handles version strings based on {http://guides.rubygems.org/patterns/}
      #
      # SUPPORTED FORMATS
      # -----------------
      # ```text
      # MAJOR.MINOR.PATCH.PRERELEASE
      # MAJOR.MINOR.PATCH.PRERELEASE-ITERATION
      # ```
      #
      # EXAMPLES
      # --------
      # ```text
      # 10.1.1
      # 10.1.1.alpha.1
      # 10.1.1.beta.1
      # 10.1.1.rc.0
      # 10.16.2
      # ```
      #
      # @author Seth Chisamore (<schisamo@chef.io>)
      # @author Christopher Maier (<cm@chef.io>)
      class Rubygems < Format
        RUBYGEMS_REGEX = /^(\d+)\.(\d+)\.(\d+)(?:\.([[:alnum:]]+(?:\.[[:alnum:]]+)?))?(?:\-(\d+))?$/

        # @see Format#parse
        def parse(version_string)
          match = version_string.match(RUBYGEMS_REGEX) rescue nil

          unless match
            raise Mixlib::Versioning::ParseError, "'#{version_string}' is not a valid #{self.class} version string!"
          end

          @major, @minor, @patch, @prerelease, @iteration = match[1..5]
          @major, @minor, @patch = [@major, @minor, @patch].map(&:to_i)

          # Do not convert @prerelease or @iteration to an integer;
          # sorting logic will handle the conversion.
          @iteration = if @iteration.nil? || @iteration.empty?
                         nil
                       else
                         @iteration.to_i
                       end
          @prerelease = nil if @prerelease.nil? || @prerelease.empty?
        end
      end # class Rubygems
    end # class Format
  end # module Versioning
end # module Mixlib
