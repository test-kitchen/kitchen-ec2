# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
      module Modernize
        # Provides should be set using the `provides` resource DSL method instead of instead of setting @provides in the initialize method.
        #
        # @example
        #
        #   ### incorrect
        #   def initialize(*args)
        #     super
        #     @provides = :foo
        #   end
        #
        #   ### correct
        #   provides :foo
        #
        class ProvidesFromInitialize < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'Provides should be set using the `provides` resource DSL method instead of instead of setting @provides in the initialize method.'

          def_node_matcher :provides_assignment?, <<-PATTERN
            (ivasgn :@provides $(sym ...))
          PATTERN

          def on_ivasgn(node)
            provides_assignment?(node) do
              return unless initialize_method(node.parent.parent).any?
              add_offense(node, severity: :refactor) do |corrector|
                # insert the new provides call above the initialize method, but not if one already exists (this is sadly common)
                unless provides_method?(processed_source.ast)
                  initialize_node = initialize_method(processed_source.ast).first
                  corrector.insert_before(initialize_node.source_range, "provides #{node.descendants.first.source}\n\n")
                end

                # remove the variable from the initialize method
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end

          def_node_search :provides_method?, '(send nil? :provides ... )'

          def_node_search :initialize_method, '(def :initialize ... )'
        end
      end
    end
  end
end
