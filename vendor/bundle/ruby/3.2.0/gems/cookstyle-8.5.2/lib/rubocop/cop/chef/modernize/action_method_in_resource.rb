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
        # Use the custom resource language's `action :my_action` blocks instead of creating actions with methods.
        #
        # @example
        #
        #   ### incorrect
        #   def action_create
        #    # :create action code here
        #   end
        #
        #   ### correct
        #   action :create do
        #    # :create action code here
        #   end
        #
        class ActionMethodInResource < Base
          extend AutoCorrector

          MSG = "Use the custom resource language's `action :my_action` blocks instead of creating actions with methods."

          def_node_search :includes_poise?, '(send nil? :include (const nil? :Poise))'

          def on_def(node)
            return unless node.method_name.to_s.start_with?('action_') # when we stop support for Ruby < 2.7 the .to_s can go away here
            return if node.arguments? # if they passed in arguments they may actually need this
            return if node.parent && includes_poise?(node.parent)

            add_offense(node, severity: :refactor) do |corrector|
              # @todo when we drop ruby 2.4 support we can convert this to use delete_suffix
              corrector.replace(node, node.source.gsub("def #{node.method_name}", "action :#{node.method_name.to_s.gsub(/^action_/, '')} do"))
            end
          end
        end
      end
    end
  end
end
