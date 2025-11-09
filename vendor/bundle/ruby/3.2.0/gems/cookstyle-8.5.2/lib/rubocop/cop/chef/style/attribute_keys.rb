# frozen_string_literal: true
#
# Copyright:: 2016, Noah Kantrowitz
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
        # Check which style of keys are used to access node attributes.
        #
        # There are two supported styles: "symbols" and "strings".
        #
        # @example when configuration is `EnforcedStyle: symbols`
        #
        #   ### incorrect
        #   node['foo']
        #   node["foo"]
        #
        #   ### correct
        #   node[:foo]
        #
        # @example when configuration is `EnforcedStyle: strings`
        #
        #   ### incorrect
        #   node[:foo]
        #
        #   ### correct
        #   node['foo']
        #   node["foo"]
        #
        class AttributeKeys < Base
          extend AutoCorrector
          include RuboCop::Cop::ConfigurableEnforcedStyle

          MSG = 'Use %s to access node attributes'
          RESTRICT_ON_SEND = [:[]].freeze

          def_node_matcher :node_attribute_access?, <<-PATTERN
            (send (send _ :node) :[] _)
          PATTERN

          def_node_matcher :node_level_attribute_access?, <<-PATTERN
            (send (send {(send _ :node) nil} {:default :role_default :env_default :normal :override :role_override :env_override :force_override :automatic}) :[] _)
          PATTERN

          def on_send(node)
            if node_attribute_access?(node) || node_level_attribute_access?(node)
              # node is first child for #[], need to look for the outermost parent too.
              outer_node = node
              while outer_node.parent && outer_node.parent.send_type? && outer_node.parent.children[1] == :[]
                on_node_attribute_access(outer_node.children[2])
                outer_node = outer_node.parent
              end
              # One last time for the outer-most access.
              on_node_attribute_access(outer_node.children[2])
            end
          end

          def on_node_attribute_access(node)
            if node.str_type?
              style_detected(:strings)
              if style == :symbols
                add_offense(node, message: MSG % style, severity: :refactor) do |corrector|
                  key_string = node.children.first.to_s
                  corrector.replace(node, key_string.to_sym.inspect)
                end
              end
            elsif node.sym_type?
              style_detected(:symbols)
              if style == :strings
                add_offense(node, message: MSG % style, severity: :refactor) do |corrector|
                  key_string = node.children.first.to_s
                  corrector.replace(node, key_string.inspect)
                end
              end
            end
          end
        end
      end
    end
  end
end
