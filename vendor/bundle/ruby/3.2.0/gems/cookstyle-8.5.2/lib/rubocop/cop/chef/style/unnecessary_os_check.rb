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
        # Use the platform_family?() helpers instead of node['os] == 'foo' for platform_families that match one-to-one with OS values. These helpers are easier to read and can accept multiple platform arguments, which greatly simplifies complex platform logic. All values of `os` from Ohai match one-to-one with `platform_family` values except for `linux`, which has no single equivalent `platform_family`.
        #
        # @example
        #
        #   ### incorrect
        #   node['os'] == 'darwin'
        #   node['os'] == 'windows'
        #   node['os'].eql?('aix')
        #   %w(netbsd openbsd freebsd).include?(node['os'])
        #
        #   ### correct
        #   platform_family?('mac_os_x')
        #   platform_family?('windows')
        #   platform_family?('aix')
        #   platform_family?('netbsd', 'openbsd', 'freebsd)
        #
        class UnnecessaryOSCheck < Base
          extend AutoCorrector

          MSG = "Use the platform_family?() helpers instead of node['os] == 'foo' for platform_families that match 1:1 with OS values."
          RESTRICT_ON_SEND = [:==, :!=, :eql?, :include?].freeze

          # sorted list of all the os values that match 1:1 with a platform_family
          UNNECESSARY_OS_VALUES = %w(aix darwin dragonflybsd freebsd netbsd openbsd solaris2 windows).freeze

          def_node_matcher :os_equals?, <<-PATTERN
            (send (send (send nil? :node) :[] (str "os") ) ${:== :!=} $str )
          PATTERN

          def_node_matcher :os_eql?, <<-PATTERN
          (send (send (send nil? :node) :[] (str "os") ) :eql? $str )
          PATTERN

          def_node_matcher :os_include?, <<-PATTERN
            (send $(array ...) :include? (send (send nil? :node) :[] (str "os")))
          PATTERN

          def on_send(node)
            os_equals?(node) do |operator, val|
              return unless UNNECESSARY_OS_VALUES.include?(val.value)
              add_offense(node, severity: :refactor) do |corrector|
                corrected_string = (operator == :!= ? '!' : '') + "platform_family?('#{sanitized_platform(val.value)}')"
                corrector.replace(node, corrected_string)
              end
            end

            os_eql?(node) do |val|
              return unless UNNECESSARY_OS_VALUES.include?(val.value)
              add_offense(node, severity: :refactor) do |corrector|
                corrected_string = "platform_family?('#{sanitized_platform(val.value)}')"
                corrector.replace(node, corrected_string)
              end
            end

            os_include?(node) do |val|
              array_of_plats = array_from_ast(val)
              # see if all the values in the .include? usage are in our list of 1:1 platform family to os values
              return unless (UNNECESSARY_OS_VALUES & array_of_plats) == array_of_plats
              add_offense(node, severity: :refactor) do |corrector|
                platforms = val.values.map { |x| x.str_type? ? "'#{sanitized_platform(x.value)}'" : x.source }
                corrected_string = "platform_family?(#{platforms.join(', ')})"
                corrector.replace(node, corrected_string)
              end
            end
          end

          # return the passed value unless the value is darwin and then return mac_os_x
          def sanitized_platform(plat)
            plat == 'darwin' ? 'mac_os_x' : plat
          end

          # given an ast array spit out a ruby array
          def array_from_ast(ast)
            vals = []
            ast.each_child_node { |x| vals << x.value }
            vals.sort
          end
        end
      end
    end
  end
end
