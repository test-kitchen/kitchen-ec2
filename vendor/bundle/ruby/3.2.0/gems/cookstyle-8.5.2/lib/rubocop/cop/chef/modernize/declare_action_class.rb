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
        # In Chef Infra Client 12.9 and later `action_class` can be used instead of `declare_action_class`.
        #
        # @example
        #
        #   ### incorrect
        #   declare_action_class do
        #     foo
        #   end
        #
        #   ### correct
        #   action_class do
        #     foo
        #   end
        #
        class DeclareActionClass < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.9'

          MSG = 'In Chef Infra Client 12.9 and later `action_class` can be used instead of `declare_action_class`.'
          RESTRICT_ON_SEND = [:declare_action_class].freeze

          def on_send(node)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.source.gsub('declare_action_class', 'action_class'))
            end
          end
        end
      end
    end
  end
end
