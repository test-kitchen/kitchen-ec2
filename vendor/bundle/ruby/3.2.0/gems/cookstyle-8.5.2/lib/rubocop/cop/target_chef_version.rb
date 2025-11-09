# frozen_string_literal: true

# shamelessly borrowed from rubocop-rails. Thanks!

module RuboCop
  module Cop
    # Common functionality for checking target chef version.
    module TargetChefVersion
      def required_minimum_chef_version
        @minimum_target_chef_version
      end

      def minimum_target_chef_version(version)
        @minimum_target_chef_version = version
      end

      def support_target_chef_version?(version)
        Gem::Version.new(@minimum_target_chef_version) <= Gem::Version.new(version)
      end
    end
  end
end
