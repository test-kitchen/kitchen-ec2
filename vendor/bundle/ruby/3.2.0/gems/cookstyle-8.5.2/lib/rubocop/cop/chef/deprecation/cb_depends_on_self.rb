# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # Make sure a cookbook doesn't depend on itself. This will fail on Chef Infra Client 13+
        #
        # @example
        #
        #   ### incorrect
        #   name 'foo'
        #   depends 'foo'
        #
        #   ### correct
        #   name 'foo'
        #
        class CookbooksDependsOnSelf < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'A cookbook cannot depend on itself. This will fail on Chef Infra Client 13+'
          RESTRICT_ON_SEND = [:name].freeze

          def_node_search :dependencies, '(send nil? :depends str ...)'
          def_node_matcher :cb_name?, '(send nil? :name str ...)'

          def on_send(node)
            cb_name?(node) do
              dependencies(processed_source.ast).each do |dep|
                next unless dep.arguments == node.arguments
                add_offense(dep, severity: :refactor) do |corrector|
                  corrector.remove(range_with_surrounding_space(range: dep.loc.expression, side: :left))
                end
              end
            end
          end
        end
      end
    end
  end
end
