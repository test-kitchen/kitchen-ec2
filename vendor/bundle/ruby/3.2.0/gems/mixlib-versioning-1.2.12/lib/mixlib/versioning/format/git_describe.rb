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
      # Handles version strings based on
      # {https://www.kernel.org/pub/software/scm/git/docs/git-describe.html git describe}
      # output.
      #
      # SUPPORTED FORMATS
      # -----------------
      # ```text
      # MAJOR.MINOR.PATCH-COMMITS_SINCE-gGIT_SHA1
      # MAJOR.MINOR.PATCH.PRERELEASE-COMMITS_SINCE-gGIT_SHA1
      # MAJOR.MINOR.PATCH-PRERELEASE-COMMITS_SINCE-gGIT_SHA1-ITERATION
      # ```
      #
      # EXAMPLES
      # --------
      # ```text
      # 10.16.2-49-g21353f0-1
      # 10.16.2.rc.1-49-g21353f0-1
      # 11.0.0-alpha-10-g642ffed
      # 11.0.0-alpha.1-1-gcea071e
      # ```
      #
      # @author Seth Chisamore (<schisamo@chef.io>)
      # @author Christopher Maier (<cm@chef.io>)
      class GitDescribe < Format
        GIT_DESCRIBE_REGEX = /^(\d+)\.(\d+)\.(\d+)(?:\-|\.)?(.+)?\-(\d+)\-g([a-f0-9]{7,40})(?:\-)?(\d+)?$/

        attr_reader :commits_since, :commit_sha

        # @see Format#parse
        def parse(version_string)
          match = version_string.match(GIT_DESCRIBE_REGEX) rescue nil

          unless match
            raise Mixlib::Versioning::ParseError, "'#{version_string}' is not a valid #{self.class} version string!"
          end

          @major, @minor, @patch, @prerelease, @commits_since, @commit_sha, @iteration = match[1..7]
          @major, @minor, @patch, @commits_since, @iteration = [@major, @minor, @patch, @commits_since, @iteration].map(&:to_i)

          # Our comparison logic is built around SemVer semantics, so
          # we'll store our internal information in that format
          @build = "#{@commits_since}.g#{@commit_sha}.#{@iteration}"
        end
      end # class GitDescribe
    end # class Format
  end # module Versioning
end # module Mixlib
