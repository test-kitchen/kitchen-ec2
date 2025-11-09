# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
      module Deprecations
        # The node.deep_fetch method has been removed from Chef-Sugar, and must be replaced by the node.read API.
        #
        # @example
        #
        #   ### incorrect
        #   node.deep_fetch("foo")
        #
        #   ### correct
        #   node.read("foo")
        #
        #   ### incorrect
        #   node.deep_fetch!("foo")
        #
        #   ### correct
        #   node.read!("foo")
        #
        class NodeDeepFetch < Base
          extend RuboCop::Cop::AutoCorrector

          RESTRICT_ON_SEND = [:deep_fetch, :deep_fetch!].freeze

          def_node_matcher :node_deep_fetch?, <<-PATTERN
            (send (send _ :node) ${:deep_fetch :deep_fetch!} _)
          PATTERN

          def on_send(node)
            node_deep_fetch?(node) do
              add_offense(node.loc.selector, message: "Do not use node.#{node.method_name}. Replace with node.#{fix_name(node.method_name)} to keep identical behavior.", severity: :warning) do |corrector|
                corrector.replace(node.loc.selector, fix_name(node.method_name))
              end
            end
          end

          private

          def fix_name(name)
            return 'read!' if name == :deep_fetch!
            return 'read' if name == :deep_fetch
            name.to_s
          end
        end
      end
    end
  end
end
