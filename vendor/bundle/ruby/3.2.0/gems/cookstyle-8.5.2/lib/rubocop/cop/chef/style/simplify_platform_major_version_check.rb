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
        # When checking the major version number of a platform you can take the node['platform_version'] attribute and transform it to an integer to strip it down to just the major version number. This simple way of determining the major version number of a platform should be used instead of splitting the platform into multiple fields with '.' as the delimiter.
        #
        # @example
        #
        #   ### incorrect
        #   node['platform_version'].split('.').first
        #   node['platform_version'].split('.')[0]
        #   node['platform_version'].split('.').first.to_i
        #   node['platform_version'].split('.')[0].to_i
        #
        #   ### correct
        #
        #   # check to see if we're on RHEL 7 on a RHEL 7.6 node where node['platform_version] is 7.6.1810
        #   if node['platform_version'].to_i == 7
        #     # some code
        #   end
        #
        class SimplifyPlatformMajorVersionCheck < Base
          extend AutoCorrector

          MSG = "Use node['platform_version'].to_i instead of node['platform_version'].split('.').first or node['platform_version'].split('.')[0]"
          RESTRICT_ON_SEND = [:split].freeze

          def_node_matcher :platform_version_check?, <<-PATTERN
            (send (send (send nil? :node) :[] (str "platform_version") ) :split (str ".") )
          PATTERN

          def on_send(node)
            platform_version_check?(node) do
              if parent_method_equals?(node, :[])
                node = node.parent
                if node&.arguments.one? &&
                   node&.arguments&.first&.int_type? &&
                   node&.arguments&.first.source == '0'
                  add_offense_to_i_if_present(node)
                end
              elsif parent_method_equals?(node, :first)
                node = node.parent
                add_offense_to_i_if_present(node)
              end
            end
          end

          private

          # if the parent is .to_i then we want to alert on that
          def add_offense_to_i_if_present(node)
            node = node.parent if parent_method_equals?(node, :to_i)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, "node['platform_version'].to_i")
            end
          end

          # see if the parent is a method and if it equals the passed in name
          #
          # @param [Rubocop::AST:Node] node The rubocop ast node to search
          # @param [Symbol] name The method name
          #
          def parent_method_equals?(node, name)
            return false if node.parent.nil?
            return false unless node.parent.send_type?
            name == node.parent.method_name
          end
        end
      end
    end
  end
end
