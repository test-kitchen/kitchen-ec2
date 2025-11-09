# frozen_string_literal: true
#
# Copyright:: Chef Software, Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
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
      module Ruby
        # Rubygems does not need to be required in a Gemspec. It's already loaded out of the box in Ruby now.
        class GemspecRequireRubygems < Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          MSG = "Rubygems does not need to be required in a Gemspec. It's already loaded out of the box in Ruby now."

          def_node_matcher :require_rubygems?, <<-PATTERN
            (send nil? :require (str "rubygems") )
          PATTERN

          def on_send(node)
            require_rubygems?(node) do |_r|
              node = node.parent if node.parent && node.parent.conditional? # make sure we identify conditionals on the require
              add_offense(node.loc.expression, message: MSG, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
