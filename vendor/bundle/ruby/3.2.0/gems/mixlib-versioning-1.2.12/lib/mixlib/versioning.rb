#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Christopher Maier (<cm@chef.io>)
# Copyright:: Copyright (c) 2013-2018 Chef Software Inc.
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

require_relative "versioning/exceptions"
require_relative "versioning/format"

module Mixlib
  # @author Seth Chisamore (<schisamo@chef.io>)
  # @author Christopher Maier (<cm@chef.io>)
  class Versioning
    DEFAULT_FORMATS = [
      Mixlib::Versioning::Format::GitDescribe,
      Mixlib::Versioning::Format::OpscodeSemVer,
      Mixlib::Versioning::Format::SemVer,
      Mixlib::Versioning::Format::Rubygems,
      Mixlib::Versioning::Format::PartialSemVer,
    ].freeze

    # Create a new {Format} instance given a version string to parse, and an
    # optional format type.
    #
    # @example
    #   Mixlib::Versioning.parse('11.0.0')
    #   Mixlib::Versioning.parse('11.0.0', :semver)
    #   Mixlib::Versioning.parse('11.0.0', 'semver')
    #   Mixlib::Versioning.parse('11.0.0', Mixlib::Versioning::Format::SemVer)
    #
    # @param version_string [String] String representatin of the version to
    #   parse
    # @param format [String, Symbol, Mixlib::Versioning::Format, Array] Optional
    #   format type to parse the version string as. If this is exluded all
    #   version types will be attempted from most specific to most specific
    #   with a preference for SemVer formats. If it is an array, only version
    #   types in that list will be considered
    # @raise [Mixlib::Versioning::ParseError] if the parse fails.
    # @raise [Mixlib::Versioning::UnknownFormatError] if the given format type
    #   doesn't exist.
    #
    # @return
    #
    def self.parse(version_string, format = nil)
      if version_string.is_a?(Mixlib::Versioning::Format)
        version_string
      else
        formats = if format
                    [format].flatten.map { |f| Mixlib::Versioning::Format.for(f) }
                  else
                    DEFAULT_FORMATS
                  end
        # Attempt to parse from the most specific formats first.
        parsed_version = nil
        formats.each do |version|
          begin
            break parsed_version = version.new(version_string)
          rescue Mixlib::Versioning::ParseError
            next
          end
        end
        parsed_version
      end
    end

    # Selects the most recent version from `all_versions` that satisfies the
    # filtering constraints provided by `filter_version`,
    # `use_prerelease_versions`, and `use_build_versions`.
    #
    # If `filter_version` specifies a release (e.g. 1.0.0), then the target
    # version that is returned will be in the same "release line" (it will have
    # the same major, minor, and patch versions), subject to filtering by
    # `use_prerelease_versions` and `use_build_versions`.
    #
    # If `filter_version` specifies a pre-release (e.g., 1.0.0-alpha.1), the
    # returned target version will be in the same "pre-release line", and will
    # only be subject to further filtering by `use_build_versions`; that is,
    # `use_prerelease_versions` is completely ignored.
    #
    # If `filter_version` specifies a build version (whether it is a
    # pre-release or not), no filtering is performed at all, and
    # `filter_version` *is* the target version; `use_prerelease_versions` and
    # `use_build_versions` are both ignored.
    #
    # If `filter_version` is `nil`, then only `use_prerelease_versions` and
    # `use_build_versions` are used for filtering.
    #
    # In all cases, the returned {Format} is the most recent one in
    # `all_versions` that satisfies the given constraints.
    #
    # @example
    #   all = %w{ 11.0.0-beta.1
    #             11.0.0-rc.1
    #             11.0.0
    #             11.0.1 }
    #
    #   Mixlib::Versioning.find_target_version(all,
    #                                          '11.0.1',
    #                                          true,
    #                                          true)
    #
    #
    # @param all_versions [Array<String, Mixlib::Versioning::Format>] An array
    #   of {Format} objects. This is the "world" of versions we will be
    #   filtering to produce the final target version. Any strings in the array
    #   will automatically be converted into instances of {Format} using
    #   {Versioning.parse}.
    # @param filter_version [String, Mixlib::Versioning::Format] A version that
    #   is used to perform more fine-grained filtering. If a string is passed,
    #   {Versioning.parse} will be used to instantiate a version.
    # @param use_prerelease_versions [Boolean] If true, keep versions with
    #   pre-release specifiers. When false, versions in `all_versions` that
    #   have a pre-release specifier will be filtered out.
    # @param use_build_versions [Boolean] If true, keep versions with build
    #   version specifiers. When false, versions in `all_versions` that have a
    #   build version specifier will be filtered out.
    #
    def self.find_target_version(all_versions,
                                 filter_version = nil,
                                 use_prerelease_versions = false,
                                 use_build_versions = false)

      # attempt to parse a `Mixlib::Versioning::Format` instance if we were
      # passed a string
      unless filter_version.nil? ||
          filter_version.is_a?(Mixlib::Versioning::Format)
        filter_version = Mixlib::Versioning.parse(filter_version)
      end

      all_versions.map! do |v|
        if v.is_a?(Mixlib::Versioning::Format)
          v
        else
          Mixlib::Versioning.parse(v)
        end
      end

      if filter_version && filter_version.build
        # If we've requested a build (whether for a pre-release or release),
        # there's no sense doing any other filtering; just return that version
        filter_version
      elsif filter_version && filter_version.prerelease
        # If we've requested a prerelease version, we only need to see if we
        # want a build version or not.  If so, keep only the build version for
        # that prerelease, and then take the most recent. Otherwise, just
        # return the specified prerelease version
        if use_build_versions
          all_versions.select { |v| v.in_same_prerelease_line?(filter_version) }.max
        else
          filter_version
        end
      else
        # If we've gotten this far, we're either just interested in
        # variations on a specific release, or the latest of all versions
        # (depending on various combinations of prerelease and build status)
        all_versions.select do |v|
          # If we're given a version to filter by, then we're only
          # interested in other versions that share the same major, minor,
          # and patch versions.
          #
          # If we weren't given a version to filter by, then we don't
          # care, and we'll take everything
          in_release_line = if filter_version
                              filter_version.in_same_release_line?(v)
                            else
                              true
                            end

          in_release_line && if use_prerelease_versions && use_build_versions
                               v.prerelease_build?
                             elsif !use_prerelease_versions &&
                                 use_build_versions
                               v.release_build?
                             elsif use_prerelease_versions &&
                                 !use_build_versions
                               v.prerelease?
                             elsif !use_prerelease_versions &&
                                 !use_build_versions
                               v.release?
                             end
        end.max # select the most recent version
      end # if
    end # self.find_target_version
  end # Versioning
end # Mixlib
