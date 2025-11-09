# frozen_string_literal: true
require 'rubocop/rspec/expect_offense'
# rubocop:disable Lint/DuplicateMethods

module RuboCop
  module RSpec
    module ExpectOffense
      # Yields to a block with `parse_processed_source` patched to not raise an
      # exception.
      #
      # RSpec's `expect_offense` helper calls a method called
      # `parse_processed_source` that parses source code and raises an exception
      # if it is not valid Ruby. Raising an exception prevents RuboCop from
      # calling the cop's `on_other_file` method for checking non-Ruby files.
      def allow_invalid_ruby(&block)
        alias :parse_processed_source :_parse_invalid_source
        yield block
        alias :parse_processed_source :_orig_parse_processed_source
      end

      alias :_orig_parse_processed_source :parse_processed_source

      def _parse_invalid_source(source, file = nil)
        parse_source(source, file)
      end
    end
  end
end
