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
      module Modernize
        # Use `node.role?('foo')` to check if a node includes a role instead of `node['roles'].include?('foo')`.
        #
        # @example
        #
        #   ### incorrect
        #   node['roles'].include?('foo')
        #
        #   ### correct
        #   node.role?('foo')
        #
        class NodeRolesInclude < Base
          extend AutoCorrector

          MSG = "Use `node.role?('foo')` to check if a node includes a role instead of `node['roles'].include?('foo')`."
          RESTRICT_ON_SEND = [:include?].freeze

          def_node_matcher :node_role_include?, <<-PATTERN
          (send
            (send
              (send nil? :node) :[]
              (str "roles")) :include?
            $(...))
          PATTERN

          def on_send(node)
            node_role_include?(node) do |val|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "node.role?(#{val.source})")
              end
            end
          end
        end
      end
    end
  end
end
