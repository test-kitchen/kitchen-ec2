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
      module Style
        # Use the platform?() and platform_family?() helpers instead of a case statement that only includes a single when statement.
        #
        # @example
        #
        #   ### incorrect
        #   case node['platform']
        #   when 'ubuntu'
        #     log "We're on Ubuntu"
        #     apt_update
        #   end
        #
        #   case node['platform_family']
        #   when 'rhel'
        #     include_recipe 'yum'
        #   end
        #
        #   ### correct
        #   if platform?('ubuntu')
        #     log "We're on Ubuntu"
        #     apt_update
        #   end
        #
        #   include_recipe 'yum' if platform_family?('rhel')
        #
        class UnnecessaryPlatformCaseStatement < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Use the platform?() and platform_family?() helpers instead of a case statement that only includes a single when statement.'

          def_node_matcher :platform_case?, <<-PATTERN
          ( case $( send (send nil? :node) :[] $(str {"platform" "platform_family"})) ... )
          PATTERN

          def on_case(node)
            platform_case?(node) do |node_, type|
              return unless node&.when_branches&.one?
              add_offense(node, severity: :refactor) do |corrector|
                # we have at least one supermarket cookbook with an entirely empty platform case statement
                # we can't actually fix that so let's do nothing here.
                unless empty_case_statement?(node)
                  condition_string = node.when_branches.first.conditions.map(&:source).join(', ')

                  # single line bodies without an else statement should be transformed into `X if platform?('ubuntu')` style statements
                  # while multi-line statements should just have the case and when bits replace with `if platform?('ubuntu')`
                  if !node.else? && !node.when_branches.first.body.multiline?
                    new_source = "#{node.when_branches.first.body.source} if #{type.value}?(#{condition_string})"
                    corrector.replace(node, new_source)
                  else
                    # find the range from the beginning of the case to the end of the node['platform'] or node['platform_family']
                    case_range = node.loc.keyword.join(node_.loc.expression.end)

                    # replace the complete conditional range with a new if statement
                    corrector.replace(case_range, "if #{type.value}?(#{condition_string})")

                    # find the range from the start of the when to the end of the last argument
                    conditional_range = node.when_branches.first.conditions.last.source_range.join(node.when_branches.first.loc.keyword.begin)

                    # remove the when XYZ condition along with any leading spaces so that we remove the whole empty line
                    corrector.remove(range_with_surrounding_space(range: conditional_range, side: :left))
                  end
                end
              end
            end
          end

          private

          # determine if each branch of the case statement contains no code
          #
          # @private
          def empty_case_statement?(node)
            node.else_branch.nil? && node.when_branches.all? { |x| x.body.nil? }
          end
        end
      end
    end
  end
end
