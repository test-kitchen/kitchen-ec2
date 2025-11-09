# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software Inc.
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
        # whyrun_supported? no longer needs to be set to true as that is the default in Chef Infra Client 13+
        #
        # @example
        #
        #   ### incorrect
        #   def whyrun_supported?
        #    true
        #   end
        #
        class WhyRunSupportedTrue < Base
          extend TargetChefVersion
          extend AutoCorrector
          include RangeHelp

          minimum_target_chef_version '13.0'

          MSG = 'whyrun_supported? no longer needs to be set to true as it is the default in Chef Infra Client 13+'

          # match on both whyrun_supported? and the typo form why_run_supported?
          def_node_matcher :whyrun_true?, <<-PATTERN
            (def {:whyrun_supported? :why_run_supported?}
              (args)
              (true))
          PATTERN

          def on_def(node)
            whyrun_true?(node) do
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
