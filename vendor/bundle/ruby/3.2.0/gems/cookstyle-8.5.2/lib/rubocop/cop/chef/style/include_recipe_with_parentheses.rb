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
      module Style
        # There is no need to wrap the recipe in parentheses when using the include_recipe helper.
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe('foo::bar')
        #
        #   ### correct
        #   include_recipe 'foo::bar'
        #
        class IncludeRecipeWithParentheses < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'There is no need to wrap the recipe in parentheses when using the include_recipe helper'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :include_recipe?, <<-PATTERN
            (send nil? :include_recipe $(str _))
          PATTERN

          def on_send(node)
            include_recipe?(node) do |recipe|
              return unless node.parenthesized?

              # avoid chefspec: expect(chef_run).to include_recipe('foo')
              return if node.parent&.send_type?

              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "include_recipe #{recipe.source}")
              end
            end
          end
        end
      end
    end
  end
end
