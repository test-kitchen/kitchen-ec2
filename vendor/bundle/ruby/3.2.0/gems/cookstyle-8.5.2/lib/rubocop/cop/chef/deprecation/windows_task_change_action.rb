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
      module Deprecations
        # The :change action in the windows_task resource was removed when windows_task was added to Chef Infra Client 13+
        # The default action of :create should can now be used to create an update tasks.
        #
        # @example
        #
        #   ### incorrect
        #   windows_task 'chef ad-join leave start time' do
        #     task_name 'chef ad-join leave'
        #     start_day '06/09/2016'
        #     start_time '01:00'
        #     action [:change, :create]
        #   end
        #
        #   ### correct
        #   windows_task 'chef ad-join leave start time' do
        #     task_name 'chef ad-join leave'
        #     start_day '06/09/2016'
        #     start_time '01:00'
        #     action :create
        #   end
        #
        class WindowsTaskChangeAction < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '13.0'

          MSG = 'The :change action in the windows_task resource was removed when windows_task was added to Chef Infra Client 13+. The default action of :create should can now be used to create an update tasks.'

          def on_block(node)
            match_property_in_resource?(:windows_task, 'action', node) do |action_node|
              action_values = action_node.arguments.first

              if action_values.sym_type? # there's only a single action given
                check_action(action_values)
              else # it was an array of actions
                action_values.node_parts.each { |action| check_action(action) }
              end
            end
          end

          private

          def check_action(ast_obj)
            if ast_obj.respond_to?(:value) && ast_obj.value == :change
              add_offense(ast_obj, severity: :warning) do |corrector|
                if ast_obj.parent.send_type? # :change was the only action
                  corrector.replace(ast_obj, ':create')
                # chances are it's [:create, :change] since that's all that makes sense, but double check that theory
                elsif ast_obj.parent.child_nodes.count == 2 &&
                      ast_obj.parent.child_nodes.map(&:value).sort == [:change, :create]
                  corrector.replace(ast_obj.parent, ':create')
                end
              end
            end
          end
        end
      end
    end
  end
end
