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

require_relative "semver"

module Mixlib
  class Versioning
    class Format
      # Defines the format of the semantic version scheme used for Opscode
      # projects.  They are SemVer-2.0.0-rc.1 compliant, but we further
      # constrain the allowable strings for prerelease and build
      # signifiers for our own internal standards.
      #
      # SUPPORTED FORMATS
      # -----------------
      # ```text
      # MAJOR.MINOR.PATCH
      # MAJOR.MINOR.PATCH-alpha.INDEX
      # MAJOR.MINOR.PATCH-beta.INDEX
      # MAJOR.MINOR.PATCH-rc.INDEX
      # MAJOR.MINOR.PATCH-alpha.INDEX+YYYYMMDDHHMMSS
      # MAJOR.MINOR.PATCH-beta.INDEX+YYYYMMDDHHMMSS
      # MAJOR.MINOR.PATCH-rc.INDEX+YYYYMMDDHHMMSS
      # MAJOR.MINOR.PATCH-alpha.INDEX+YYYYMMDDHHMMSS.git.COMMITS_SINCE.SHA1
      # MAJOR.MINOR.PATCH-beta.INDEX+YYYYMMDDHHMMSS.git.COMMITS_SINCE.SHA1
      # MAJOR.MINOR.PATCH-rc.INDEX+YYYYMMDDHHMMSS.git.COMMITS_SINCE.SHA1
      # ```
      #
      # EXAMPLES
      # --------
      # ```text
      # 11.0.0
      # 11.0.0-alpha.1
      # 11.0.0-alpha1+20121218164140
      # 11.0.0-alpha1+20121218164140.git.207.694b062
      # ```
      #
      # @author Seth Chisamore (<schisamo@chef.io>)
      # @author Christopher Maier (<cm@chef.io>)
      class OpscodeSemVer < SemVer
        # The pattern is: `YYYYMMDDHHMMSS.git.COMMITS_SINCE.SHA1`
        OPSCODE_BUILD_REGEX = /^\d{14}(\.git\.\d+\.[a-f0-9]{7})?$/

        # Allows the following:
        #
        # ```text
        # alpha, alpha.0, alpha.1, alpha.2, etc.
        # beta, beta.0, beta.1, beta.2, etc.
        # rc, rc.0, rc.1, rc.2, etc.
        # ```
        #
        OPSCODE_PRERELEASE_REGEX = /^(alpha|beta|rc)(\.\d+)?$/

        # @see SemVer#parse
        def parse(version_string)
          super(version_string)

          raise Mixlib::Versioning::ParseError, "'#{@prerelease}' is not a valid Opscode pre-release signifier!" unless @prerelease.nil? || @prerelease.match(OPSCODE_PRERELEASE_REGEX)
          raise Mixlib::Versioning::ParseError, "'#{@build}' is not a valid Opscode build signifier!" unless @build.nil? || @build.match(OPSCODE_BUILD_REGEX)
        end
      end # class OpscodeSemVer
    end # class Format
  end # module Versioning
end # module Mixlib
