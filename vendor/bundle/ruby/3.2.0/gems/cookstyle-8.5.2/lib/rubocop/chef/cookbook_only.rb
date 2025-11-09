# frozen_string_literal: true

module RuboCop
  module Chef
    # Mixin for cops that skips non-cookbook files
    #
    # The criteria for whether cookstyle analyzes a certain ruby file
    # is configured via `AllCops/Chef`. For example, if you want to
    # customize your project to scan all files within a `test/` directory
    # then you could add this to your configuration:
    #
    # @example configuring analyzed paths
    #
    #   AllCops:
    #     Chef:
    #       Patterns:
    #       - '_spec.rb$'
    #       - '(?:^|/)spec/'
    #
    module CookbookOnly
      DEFAULT_CONFIGURATION = CONFIG.fetch('AllCops')
      COOKBOOK_SEGMENTS = %w(attributes definitions libraries metadata providers recipes resources).freeze

      def relevant_file?(file)
        cookbook_pattern =~ file && super
      end

      private

      def cookbook_pattern
        patterns = []
        COOKBOOK_SEGMENTS.each do |segment|
          next unless self.class.cookbook_only_segments[segment.to_sym]

          cookbook_pattern_config(segment).each do |pattern|
            patterns << Regexp.new(pattern)
          end
        end
        Regexp.union(patterns)
      end

      def cookbook_pattern_config(segment)
        config_key = "Chef#{segment.capitalize}"
        config
          .for_all_cops
          .fetch(config_key, DEFAULT_CONFIGURATION.fetch(config_key))
          .fetch('Patterns')
      end

      module ClassMethods
        attr_writer :cookbook_only_segments

        def cookbook_only_segments
          @cookbook_only_segments || Hash.new(true)
        end

        def included(klass)
          super
          klass.extend(ClassMethods)
        end
      end

      extend ClassMethods
    end

    def self.CookbookOnly(segments)
      Module.new do |mod|
        mod.define_singleton_method(:included) do |klass|
          super(klass)
          klass.include(CookbookOnly)
          klass.cookbook_only_segments = segments
        end
      end
    end
  end
end
