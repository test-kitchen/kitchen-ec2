# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software, Inc.
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
        # In Chef Infra Client 12+ is is no longer necessary to gate the use of the provides methods in resources with `if respond_to?(:provides)` or `if defined? provides`.
        #
        # @example
        #
        #   ### incorrect
        #   provides :foo if respond_to?(:provides)
        #
        #   provides :foo if defined? provides
        #
        #   ### correct
        #   provides :foo
        #
        class RespondToProvides < Base
          extend AutoCorrector

          MSG = 'Using `respond_to?(:provides)` or `if defined? provides` in resources is no longer necessary in Chef Infra Client 12+.'

          def on_if(node)
            if_respond_to_provides?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, node.children[1].source)
              end
            end
          end

          def_node_matcher :if_respond_to_provides?, <<~PATTERN
            (if
              {
              (send nil? :respond_to?
                (sym :provides))

              (:defined?
                (send nil? :provides))
              }
              (send nil? :provides
                (sym _)) ... )
          PATTERN
        end
      end
    end
  end
end
