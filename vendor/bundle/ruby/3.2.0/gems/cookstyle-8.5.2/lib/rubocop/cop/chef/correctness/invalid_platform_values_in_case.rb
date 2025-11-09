# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
      module Correctness
        # Use valid platform values in case statements. See [Infra Language: Platform](https://docs.chef.io/infra_language/checking_platforms/#platform-values) for a list of many common platform values.
        #
        # @example
        #
        #   ### incorrect
        #   case node['platform']
        #   when 'rhel'
        #     puts "I'm on a Red Hat system!"
        #   end
        #
        class InvalidPlatformInCase < Base
          extend AutoCorrector
          include RangeHelp
          include ::RuboCop::Chef::PlatformHelpers

          MSG = 'Use valid platform values in case statements.'
          RESTRICT_ON_SEND = [:[]].freeze

          def_node_matcher :node_platform?, <<-PATTERN
            (send (send nil? :node) :[] (str "platform") )
          PATTERN

          def on_case(node)
            node_platform?(node.condition) do
              node.each_when do |when_node|
                when_node.each_condition do |con|
                  next unless con.str_type? # if the condition isn't a string we can't check so skip
                  new_value = INVALID_PLATFORMS[con.str_content]
                  # some invalid platform have no direct correction value and return nil instead
                  next unless new_value

                  add_offense(con, severity: :refactor) do |corrector|
                    # if the correct value already exists in the when statement then we just want to delete this node
                    if con.parent.conditions.any? { |x| x.str_content == new_value }
                      range = range_with_surrounding_comma(range_with_surrounding_space(range: con.loc.expression, side: :left), :both)
                      corrector.remove(range)
                    else
                      corrector.replace(con, "'#{new_value}'")
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
