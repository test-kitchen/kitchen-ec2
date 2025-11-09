#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
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

require_relative "product"
require_relative "product_matrix"
require_relative "util"
require "mixlib/versioning"

module Mixlib
  class Install
    class Options
      class InvalidOptions < ArgumentError; end

      attr_reader :options, :errors, :original_platform_version, :supported_product_names

      SUPPORTED_ARCHITECTURES = %w{
        aarch64
        armv7l
        i386
        powerpc
        ppc64
        ppc64le
        s390x
        sparc
        universal
        x86_64
      }

      SUPPORTED_CHANNELS = [
        :stable,
        :current,
        :unstable,
      ]

      SUPPORTED_SHELL_TYPES = [
        :ps1,
        :sh,
      ]
      SUPPORTED_OPTIONS = [
        :architecture,
        :channel,
        :platform,
        :platform_version,
        :product_name,
        :product_version,
        :shell_type,
        :platform_version_compatibility_mode,
        :include_metadata,
        :user_agent_headers,
        :install_command_options,
      ]

      SUPPORTED_WINDOWS_DESKTOP_VERSIONS = %w{10}

      SUPPORTED_WINDOWS_NANO_VERSIONS = %w{2016nano}

      def initialize(options)
        @options = options
        @errors = []

        # Store original options in cases where we must remap
        @original_platform_version = options[:platform_version]

        # Eval extra products definition
        extra_products = ENV.fetch("EXTRA_PRODUCTS_FILE", nil)
        unless extra_products.nil?
          PRODUCT_MATRIX.instance_eval(::File.read(extra_products), extra_products)
        end

        # Store supported product names
        @supported_product_names = PRODUCT_MATRIX.products

        resolve_platform_version_compatibility_mode!

        map_windows_versions!

        validate!
      end

      SUPPORTED_OPTIONS.each do |option|
        define_method option do
          options[option] || options[option.to_s] || default_options[option]
        end
      end

      def validate!
        validate_options!
      end

      def validate_options!
        validate_architecture
        validate_product_names
        validate_channels
        validate_shell_type
        validate_user_agent_headers
        validate_platform_options

        raise InvalidOptions, errors.join("\n") unless errors.empty?
      end

      def for_ps1?
        platform == "windows" || shell_type == :ps1
      end
      alias_method :for_windows?, :for_ps1?

      def latest_version?
        product_version.to_sym == :latest
      end

      def partial_version?
        # If PartialSemVer is defined than the version of mixlib-versioning loaded can parse partial versions
        # Otherwise parsing a partial version will return nil
        is_partial = if defined?(Mixlib::Versioning::Format::PartialSemVer)
                       # remove if there's a trailing period for mixlib-versioning compatibility
                       options[:product_version] = product_version.chomp(".") if product_version.is_a? String
                       Mixlib::Versioning.parse(product_version).is_a?(Mixlib::Versioning::Format::PartialSemVer)
                     else
                       !Mixlib::Versioning.parse(product_version)
                     end

        !latest_version? && is_partial
      end

      def include_metadata?
        include_metadata.to_s == "true"
      end

      #
      # Set the platform info on the instance
      # info [Hash]
      #  Hash with keys :platform, :platform_version and :architecture
      #
      def set_platform_info(info)
        options[:platform] = info[:platform]
        options[:platform_version] = info[:platform_version]
        options[:architecture] = info[:architecture]

        validate_options!
      end

      def platform_info
        {
          platform: options[:platform],
          platform_version: options[:platform_version],
          architecture: options[:architecture],
        }
      end

      #
      # Calling this method will give queries more of an opportunity to collect
      # compatible artifacts where there may not always be an exact match.
      #
      # This option is set to false by default.
      # - In cases where no platform options are configured it will set this option to true.
      # - In cases where all platform options are configured it will remain false UNLESS the option
      #   has been configured to be true.
      #
      def resolve_platform_version_compatibility_mode!
        unless options[:platform_version_compatibility_mode]
          options[:platform_version_compatibility_mode] = true if platform_info.values.none?
        end
      end

      private

      def default_options
        {
          shell_type: :sh,
          platform_version_compatibility_mode: false,
          product_version: :latest,
          include_metadata: false,
        }
      end

      def validate_architecture
        unless architecture.nil? || SUPPORTED_ARCHITECTURES.include?(architecture)
          errors << <<-EOS
Unknown architecture #{architecture}.
Must be one of: #{SUPPORTED_ARCHITECTURES.join(", ")}
          EOS
        end
      end

      def validate_product_names
        unless @supported_product_names.include? product_name
          errors << <<-EOS
Unknown product name #{product_name}.
Must be one of: #{@supported_product_names.join(", ")}
          EOS
        end
      end

      def validate_channels
        unless SUPPORTED_CHANNELS.include? channel
          errors << <<-EOS
Unknown channel #{channel}.
Must be one of: #{SUPPORTED_CHANNELS.join(", ")}
          EOS
        end
      end

      def validate_shell_type
        unless SUPPORTED_SHELL_TYPES.include? shell_type
          errors << <<-EOS
Unknown shell type.
Must be one of: #{SUPPORTED_SHELL_TYPES.join(", ")}
          EOS
        end
      end

      def validate_user_agent_headers
        error = nil
        if user_agent_headers
          if user_agent_headers.is_a? Array
            user_agent_headers.each do |header|
              error = "user agent headers can not have spaces." if header.include?(" ")
            end
          else
            error = "user_agent_headers must be an Array."
          end
        end

        errors << error if error
      end

      def validate_platform_options
        unless all_or_none?(platform_info.values)
          errors << <<-EOS
Must provide platform (-p), platform version (-l) and architecture (-a) when specifying any platform details
          EOS
        end
      end

      def map_windows_versions!
        return unless for_windows?

        options[:platform_version] = Util.map_windows_version(platform_version)
      end

      def all_or_none?(items)
        items.all? || items.compact.empty?
      end
    end
  end
end
