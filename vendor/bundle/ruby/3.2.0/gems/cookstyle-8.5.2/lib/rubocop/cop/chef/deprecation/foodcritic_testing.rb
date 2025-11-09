# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
# Author:: Tim Smith (<tsmith84@gmail.com>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module RuboCop
  module Cop
    module Chef
      module Deprecations
        # The Foodcritic cookbook linter has been deprecated and should no longer be used for validating cookbooks.
        #
        # @example
        #
        #   ### incorrect
        #   gem 'foodcritic'
        #   require 'foodcritic'
        #
        class FoodcriticTesting < Base
          MSG = 'The Foodcritic cookbook linter has been deprecated and should no longer be used for validating cookbooks.'
          RESTRICT_ON_SEND = [:require, :gem].freeze

          def on_send(node)
            return unless node.arguments.first == s(:str, 'foodcritic')

            add_offense(node, severity: :warning)
          end
        end
      end
    end
  end
end
