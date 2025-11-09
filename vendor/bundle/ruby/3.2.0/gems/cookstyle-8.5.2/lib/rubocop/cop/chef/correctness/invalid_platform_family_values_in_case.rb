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
        # Use valid platform family values in case statements. See [Infra Language: Platform Family](https://docs.chef.io/infra_language/checking_platforms/#platform_family-values) for a complete list of platform families.
        #
        # @example
        #
        #   ### incorrect
        #   case node['platform_family']
        #   when 'redhat'
        #     puts "I'm on a RHEL-like system"
        #   end
        #
        class InvalidPlatformFamilyInCase < Base
          extend AutoCorrector
          include RangeHelp
          include ::RuboCop::Chef::PlatformHelpers

          MSG = 'Use valid platform family values in case statements.'

          def_node_matcher :node_platform_family?, <<-PATTERN
            (send (send nil? :node) :[] (str "platform_family") )
          PATTERN

          def on_case(node)
            node_platform_family?(node.condition) do
              node.each_when do |when_node|
                when_node.each_condition do |con|
                  next unless con.str_type?
                  # if the condition isn't a string we can't check so skip
                  # some invalid platform families have no direct correction value and return nil instead
                  new_value = INVALID_PLATFORM_FAMILIES[con.str_content]
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
