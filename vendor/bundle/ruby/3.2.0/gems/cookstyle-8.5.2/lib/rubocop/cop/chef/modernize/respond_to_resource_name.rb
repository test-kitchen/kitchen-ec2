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
      module Modernize
        # Chef Infra Client 12.5 introduced the resource_name method for resources. Many cookbooks used respond_to?(:resource_name) to provide backwards compatibility with older chef-client releases. This backwards compatibility is no longer necessary.
        #
        # @example
        #
        #   ### incorrect
        #   resource_name :foo if respond_to?(:resource_name)
        #
        #   ### correct
        #   resource_name :foo
        #
        class RespondToResourceName < Base
          extend AutoCorrector

          MSG = 'respond_to?(:resource_name) in resources is no longer necessary in Chef Infra Client 12.5+'

          def on_if(node)
            if_respond_to_resource_name?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, node.children[1].source)
              end
            end
          end

          def_node_matcher :if_respond_to_resource_name?, <<~PATTERN
            (if (send nil? :respond_to? ( :sym :resource_name ) ) ... )
          PATTERN
        end
      end
    end
  end
end
