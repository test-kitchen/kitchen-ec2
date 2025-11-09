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
        # Instead of using only_if conditionals with ! to negate the returned value, use not_if which is easier to read
        #
        # @example
        #
        #   ### incorrect
        #   package 'legacy-sysv-deps' do
        #     only_if { !systemd }
        #   end
        #
        #   ### correct
        #   package 'legacy-sysv-deps' do
        #     not_if { systemd }
        #   end
        #
        class NegatingOnlyIf < Base
          extend AutoCorrector

          MSG = 'Instead of using only_if conditionals with ! to negate the returned value, use not_if which is easier to read'

          def_node_matcher :negated_only_if?, <<-PATTERN
            (block
              $(send nil? :only_if)
              (args)
              $(send
                $(...) :!))
          PATTERN

          def on_block(node)
            negated_only_if?(node) do |only_if, code|
              # skip inspec controls where we don't have not_if
              return if node.parent&.parent&.block_type? &&
                        node.parent&.parent&.method_name == :control

              # the value was double negated to work around types: ex: !!systemd?
              return if code.descendants.first.send_type? &&
                        code.descendants.first.negation_method?

              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(code, code.source.gsub(/^!/, ''))
                corrector.replace(only_if.source_range, 'not_if')
              end
            end
          end
        end
      end
    end
  end
end
