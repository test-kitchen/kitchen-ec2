# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software, Inc.
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
        # In Chef Infra Client 12.9 and later it is no longer necessary to call the class_eval method on the action class block.
        #
        # @example
        #
        #   ### incorrect
        #   action_class.class_eval do
        #     foo
        #   end
        #
        #   ### correct
        #   action_class do
        #     foo
        #   end
        #
        class ClassEvalActionClass < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.9'

          MSG = 'In Chef Infra Client 12.9 and later it is no longer necessary to call the class_eval method on the action class block.'

          def_node_matcher :class_eval_action_class?, <<-PATTERN
            (block
              (send
                (send nil? :action_class) :class_eval)
              (args)
              ... )
          PATTERN

          def on_block(node)
            class_eval_action_class?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, node.source.gsub('.class_eval', ''))
              end
            end
          end
        end
      end
    end
  end
end
