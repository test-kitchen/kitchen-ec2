# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software, Inc.
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
      module RedundantCode
        # It is not necessary to set `actions` or `allowed_actions` in custom resources as Chef Infra Client determines these automatically from the set of all actions defined in the resource.
        #
        # @example
        #
        #   ### incorrect
        #   allowed_actions [:create, :remove]
        #
        #   # also bad
        #   actions [:create, :remove]
        #
        class CustomResourceWithAllowedActions < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'It is not necessary to set `actions` or `allowed_actions` in custom resources as Chef Infra Client determines these automatically from the set of all actions defined in the resource'
          RESTRICT_ON_SEND = [:allowed_actions, :actions].freeze

          def_node_search :poise_require, '(send nil? :require (str "poise"))'

          def_node_search :resource_actions?, <<-PATTERN
            (block (send nil? :action ... ) ... )
          PATTERN

          def on_send(node)
            # avoid triggering on things like new_resource.actions
            return unless node.receiver.nil?

            # if the resource requires poise then bail out since we're in a poise resource where @allowed_actions is legit
            return if poise_require(processed_source.ast).any? || !resource_actions?(processed_source.ast)

            add_offense(node, severity: :refactor) do |corrector|
              corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
            end
          end
        end
      end
    end
  end
end
