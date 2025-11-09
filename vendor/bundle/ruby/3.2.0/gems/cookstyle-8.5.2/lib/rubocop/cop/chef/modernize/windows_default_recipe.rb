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
      module Modernize
        # Don't include the windows default recipe that is either full of gem install that are part of the Chef Infra Client, or empty (depends on version).
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'windows::default'
        #   include_recipe 'windows'
        #
        class IncludingWindowsDefaultRecipe < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'Do not include the Windows default recipe, which only installs win32 gems already included in Chef Infra Client'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :windows_recipe_usage?, <<-PATTERN
            (send nil? :include_recipe (str {"windows" "windows::default"}))
          PATTERN

          def on_send(node)
            windows_recipe_usage?(node) do
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
