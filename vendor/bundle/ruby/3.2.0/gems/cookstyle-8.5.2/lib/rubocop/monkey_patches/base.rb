# frozen_string_literal: true
module RuboCop
  module Cop
    class Base
      # This is a copy of the #target_rails_version method from rubocop-rails
      def target_chef_version
        @config.target_chef_version
      end
    end
  end
end
