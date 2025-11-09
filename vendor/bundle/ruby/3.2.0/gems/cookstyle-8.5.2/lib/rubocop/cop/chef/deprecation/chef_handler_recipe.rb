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
        # There is no need to include the empty and deprecated chef_handler::default recipe to use the chef_handler resource
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'chef_handler'
        #   include_recipe 'chef_handler::default'
        #
        class ChefHandlerRecipe < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'There is no need to include the empty and deprecated chef_handler::default recipe to use the chef_handler resource'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :chef_handler_recipe?, <<-PATTERN
            (send nil? :include_recipe (str {"chef_handler" "chef_handler::default"}))
          PATTERN

          def on_send(node)
            chef_handler_recipe?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
