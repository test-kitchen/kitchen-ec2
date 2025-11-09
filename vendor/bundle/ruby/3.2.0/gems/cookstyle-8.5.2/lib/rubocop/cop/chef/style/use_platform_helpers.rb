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
        # Use the platform?() and platform_family?() helpers instead of node['platform] == 'foo' and node['platform_family'] == 'bar'. These helpers are easier to read and can accept multiple platform arguments, which greatly simplifies complex platform logic.
        #
        # @example
        #
        #   ### incorrect
        #   node['platform'] == 'ubuntu'
        #   node['platform_family'] == 'debian'
        #   node['platform'] != 'ubuntu'
        #   node['platform_family'] != 'debian'
        #   %w(rhel suse).include?(node['platform_family'])
        #   node['platform'].eql?('ubuntu')
        #
        #   ### correct
        #   platform?('ubuntu')
        #   !platform?('ubuntu')
        #   platform_family?('debian')
        #   !platform_family?('debian')
        #   platform_family?('rhel', 'suse')
        #
        class UsePlatformHelpers < Base
          extend AutoCorrector

          MSG = "Use platform? and platform_family? helpers to check a node's platform"
          RESTRICT_ON_SEND = [:==, :!=, :eql?, :include?].freeze

          def_node_matcher :platform_equals?, <<-PATTERN
            (send (send (send nil? :node) :[] $(str {"platform" "platform_family"}) ) ${:== :!=} $str )
          PATTERN

          def_node_matcher :platform_include?, <<-PATTERN
            (send $(array ...) :include? (send (send nil? :node) :[] $(str {"platform" "platform_family"})))
          PATTERN

          def_node_matcher :platform_eql?, <<-PATTERN
          (send (send (send nil? :node) :[] $(str {"platform" "platform_family"}) ) :eql? $str )
          PATTERN

          def on_send(node)
            platform_equals?(node) do |type, operator, plat|
              add_offense(node, severity: :refactor) do |corrector|
                corrected_string = (operator == :!= ? '!' : '') + "#{type.value}?('#{plat.value}')"
                corrector.replace(node, corrected_string)
              end
            end

            platform_include?(node) do |plats, type|
              add_offense(node, severity: :refactor) do |corrector|
                platforms = plats.values.map { |x| x.str_type? ? "'#{x.value}'" : x.source }
                corrected_string = "#{type.value}?(#{platforms.join(', ')})"
                corrector.replace(node, corrected_string)
              end
            end

            platform_eql?(node) do |type, plat|
              add_offense(node, severity: :refactor) do |corrector|
                corrected_string = "#{type.value}?('#{plat.value}')"
                corrector.replace(node, corrected_string)
              end
            end
          end
        end
      end
    end
  end
end
