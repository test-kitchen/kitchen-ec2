#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require_relative "format/git_describe"
require_relative "format/opscode_semver"
require_relative "format/rubygems"
require_relative "format/semver"
require_relative "format/partial_semver"

module Mixlib
  class Versioning
    # @author Seth Chisamore (<schisamo@chef.io>)
    #
    # @!attribute [r] major
    #   @return [Integer] major identifier
    # @!attribute [r] minor
    #   @return [Integer] minor identifier
    # @!attribute [r] patch
    #   @return [Integer, nil] patch identifier
    # @!attribute [r] prerelease
    #   @return [String, nil] pre-release identifier
    # @!attribute [r] build
    #   @return [String, nil] build identifier
    # @!attribute [r] iteration
    #   @return [String, nil] build interation
    # @!attribute [r] input
    #   @return [String, nil] original input version string that was parsed
    class Format
      include Comparable

      # Returns the {Mixlib::Versioning::Format} class that maps to the given
      # format type.
      #
      # @example
      #   Mixlib::Versioning::Format.for(:semver)
      #   Mixlib::Versioning::Format.for('semver')
      #   Mixlib::Versioning::Format.for(Mixlib::Versioning::Format::SemVer)
      #
      # @param format_type [String, Symbol, Mixlib::Versioning::Format] Name of
      #   a valid +Mixlib::Versioning::Format+ in Class or snake-case form.
      #
      # @raise [Mixlib::Versioning::UnknownFormatError] if the given format
      #   type doesn't exist
      #
      # @return [Class] the {Mixlib::Versioning::Format} class
      #
      def self.for(format_type)
        if format_type.is_a?(Class) &&
            format_type.ancestors.include?(Mixlib::Versioning::Format)
          format_type
        else
          case format_type.to_s
          when "semver" then Mixlib::Versioning::Format::SemVer
          when "opscode_semver" then Mixlib::Versioning::Format::OpscodeSemVer
          when "git_describe" then Mixlib::Versioning::Format::GitDescribe
          when "rubygems" then Mixlib::Versioning::Format::Rubygems
          when "partial_semver" then Mixlib::Versioning::Format::PartialSemVer
          else
            msg = "'#{format_type}' is not a supported Mixlib::Versioning format"
            raise Mixlib::Versioning::UnknownFormatError, msg
          end
        end
      end

      attr_reader :major, :minor, :patch, :prerelease, :build, :iteration, :input

      # @param version_string [String] string representation of the version
      def initialize(version_string)
        parse(version_string)
        @input = version_string
      end

      # Parses the version string splitting it into it's component version
      # identifiers for easy comparison and sorting of versions. This method
      # **MUST** be overriden by all descendants of this class.
      #
      # @param version_string [String] string representation of the version
      # @raise [Mixlib::Versioning::ParseError] raised if parsing fails
      def parse(_version_string)
        raise Error, "You must override the #parse"
      end

      # @return [Boolean] Whether or not this is a release version
      def release?
        @prerelease.nil? && @build.nil?
      end

      # @return [Boolean] Whether or not this is a pre-release version
      def prerelease?
        !@prerelease.nil? && @build.nil?
      end

      # @return [Boolean] Whether or not this is a release build version
      def release_build?
        @prerelease.nil? && !@build.nil?
      end

      # @return [Boolean] Whether or not this is a pre-release build version
      def prerelease_build?
        !@prerelease.nil? && !@build.nil?
      end

      # @return [Boolean] Whether or not this is a build version
      def build?
        !@build.nil?
      end

      # Returns `true` if `other` and this {Format} share the same `major`,
      # `minor`, and `patch` values. Pre-release and build specifiers are not
      # taken into consideration.
      #
      # @return [Boolean]
      def in_same_release_line?(other)
        @major == other.major &&
          @minor == other.minor &&
          @patch == other.patch
      end

      # Returns `true` if `other` an share the same
      # `major`, `minor`, and `patch` values. Pre-release and build specifiers
      # are not taken into consideration.
      #
      # @return [Boolean]
      def in_same_prerelease_line?(other)
        @major == other.major &&
          @minor == other.minor &&
          @patch == other.patch &&
          @prerelease == other.prerelease
      end

      # @return [String] String representation of this {Format} instance
      def to_s
        @input
      end

      # Since the default implementation of `Object#inspect` uses `Object#to_s`
      # under the covers (which we override) we need to also override `#inspect`
      # to ensure useful debug information.
      def inspect
        vars = instance_variables.map do |n|
          "#{n}=#{instance_variable_get(n).inspect}"
        end
        format("#<%s:0x%x %s>", self.class, object_id, vars.join(", "))
      end

      # Returns SemVer compliant string representation of this {Format}
      # instance. The string returned will take on the form:
      #
      # ```text
      # MAJOR.MINOR.PATCH-PRERELEASE+BUILD
      # ```
      #
      # @return [String] SemVer compliant string representation of this
      #   {Format} instance
      # @todo create a proper serialization abstraction
      def to_semver_string
        s = [@major, @minor, @patch].map(&:to_i).join(".")
        s += "-#{@prerelease}" if @prerelease
        s += "+#{@build}" if @build
        s
      end

      # Returns Rubygems compliant string representation of this {Format}
      # instance. The string returned will take on the form:
      #
      # ```text
      # MAJOR.MINOR.PATCH.PRERELEASE
      # ```
      #
      # @return [String] Rubygems compliant string representation of this
      #   {Format} instance
      # @todo create a proper serialization abstraction
      def to_rubygems_string
        s = [@major, @minor, @patch].map(&:to_i).join(".")
        s += ".#{@prerelease}" if @prerelease
        s
      end

      # Compare this version number with the given version number, following
      # Semantic Versioning 2.0.0-rc.1 semantics.
      #
      # @param other [Mixlib::Versioning::Format]
      # @return [Integer] -1, 0, or 1 depending on whether the this version is
      #   less than, equal to, or greater than the other version
      def <=>(other)
        # Check whether the `other' is a String and if so, then get an
        # instance of *this* class (e.g., GitDescribe, OpscodeSemVer,
        # SemVer, Rubygems, etc.), so we can compare against it.
        other = self.class.new(other) if other.is_a?(String)

        # First, perform comparisons based on major, minor, and patch
        # versions.  These are always presnt and always non-nil
        maj = @major <=> other.major
        return maj unless maj == 0

        min = @minor <=> other.minor
        return min unless min == 0

        pat = @patch <=> other.patch
        return pat unless pat == 0

        # Next compare pre-release specifiers.  A pre-release sorts
        # before a release (e.g. 1.0.0-alpha.1 comes before 1.0.0), so
        # we need to take nil into account in our comparison.
        #
        # If both have pre-release specifiers, we need to compare both
        # on the basis of each component of the specifiers.
        if @prerelease && other.prerelease.nil?
          return -1
        elsif @prerelease.nil? && other.prerelease
          return 1
        elsif @prerelease && other.prerelease
          pre = compare_dot_components(@prerelease, other.prerelease)
          return pre unless pre == 0
        end

        # Build specifiers are compared like pre-release specifiers,
        # except that builds sort *after* everything else
        # (e.g. 1.0.0+build.123 comes after 1.0.0, and
        # 1.0.0-alpha.1+build.123 comes after 1.0.0-alpha.1)
        if @build.nil? && other.build
          return -1
        elsif @build && other.build.nil?
          return 1
        elsif @build && other.build
          build_ver = compare_dot_components(@build, other.build)
          return build_ver unless build_ver == 0
        end

        # Some older version formats improperly include a package iteration in
        # the version string. This is different than a build specifier and
        # valid release versions may include an iteration. We'll transparently
        # handle this case and compare iterations if it was parsed by the
        # implementation class.
        if @iteration.nil? && other.iteration
          return -1
        elsif @iteration && other.iteration.nil?
          return 1
        elsif @iteration && other.iteration
          return @iteration <=> other.iteration
        end

        # If we get down here, they're both equal
        0
      end

      # @param other [Mixlib::Versioning::Format]
      # @return [Boolean] returns true if the versions are equal, false
      #   otherwise.
      def eql?(other)
        @major == other.major &&
          @minor == other.minor &&
          @patch == other.patch &&
          @prerelease == other.prerelease &&
          @build == other.build
      end

      def hash
        [@major, @minor, @patch, @prerelease, @build].compact.join(".").hash
      end

      #########################################################################

      private

      # If a String `n` can be parsed as an Integer do so; otherwise, do
      # nothing.
      #
      # @param n [String, nil]
      # @return [Integer] the parsed {Integer}
      def maybe_int(n)
        Integer(n)
      rescue
        n
      end

      # Compares prerelease and build version component strings
      # according to SemVer 2.0.0-rc.1 semantics.
      #
      # Returns -1, 0, or 1, just like the spaceship operator (`<=>`),
      # and is used in the implemntation of `<=>` for this class.
      #
      # Pre-release and build specifiers are dot-separated strings.
      # Numeric components are sorted numerically; otherwise, sorting is
      # standard ASCII order.  Numerical components have a lower
      # precedence than string components.
      #
      # See http://www.semver.org for more.
      #
      # Both `a_item` and `b_item` should be Strings; `nil` is not a
      # valid input.
      def compare_dot_components(a_item, b_item)
        a_components = a_item.split(".")
        b_components = b_item.split(".")

        max_length = [a_components.length, b_components.length].max

        (0..(max_length - 1)).each do |i|
          # Convert the ith component into a number if possible
          a = maybe_int(a_components[i])
          b = maybe_int(b_components[i])

          # Since the components may be of differing lengths, the
          # shorter one will yield +nil+ at some point as we iterate.
          if a.nil? && !b.nil?
            # a_item was shorter
            return -1
          elsif !a.nil? && b.nil?
            # b_item was shorter
            return 1
          end

          # Now we need to compare appropriately based on type.
          #
          # Numbers have lower precedence than strings; therefore, if
          # the components are of different types (String vs. Integer),
          # we just return -1 for the numeric one and we're done.
          #
          # If both are the same type (Integer vs. Integer, or String
          # vs. String), we can just use the native comparison.
          #
          if a.is_a?(Integer) && b.is_a?(String)
            # a_item was "smaller"
            return -1
          elsif a.is_a?(String) && b.is_a?(Integer)
            # b_item was "smaller"
            return 1
          else
            comp = a <=> b
            return comp unless comp == 0
          end
        end # each

        # We've compared all components of both strings; if we've gotten
        # down here, they're totally the same
        0
      end
    end # Format
  end # Versioning
end # Mixlib
