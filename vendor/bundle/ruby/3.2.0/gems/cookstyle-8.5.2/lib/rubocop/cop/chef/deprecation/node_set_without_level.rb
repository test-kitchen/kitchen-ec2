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
        # When setting a node attribute in Chef Infra Client 11 and later you must specify the precedence level.
        #
        # @example
        #
        #   ### incorrect
        #   node['foo']['bar'] = 1
        #   node['foo']['bar'] << 1
        #   node['foo']['bar'] += 1
        #   node['foo']['bar'] -= 1
        #
        #   ### correct
        #   node.default['foo']['bar'] = 1
        #   node.default['foo']['bar'] << 1
        #   node.default['foo']['bar'] += 1
        #   node.default['foo']['bar'] -= 1
        #
        class NodeSetWithoutLevel < Base
          MSG = 'When setting a node attribute in Chef Infra Client 11 and later you must specify the precedence level.'
          RESTRICT_ON_SEND = [:[]=, :<<].freeze

          def on_op_asgn(node)
            # make sure it was a += or -=
            if %i(- +).include?(node.node_parts[1])
              add_offense_for_bare_assignment(node.children&.first)
            end
          end

          def on_send(node)
            # make sure the method being send is []= and then make sure the receiver is a send
            if %i([]= <<).include?(node.method_name) && node.receiver.send_type?
              add_offense_for_bare_assignment(node)
            end
          end

          private

          def add_offense_for_bare_assignment(sub_node)
            if sub_node.receiver == s(:send, nil, :node) # node['foo'] scenario
              add_offense(sub_node.receiver.loc.selector, severity: :warning)
            elsif sub_node.receiver &&
                  sub_node.receiver&.node_parts.first == s(:send, nil, :node) &&
                  sub_node.receiver&.node_parts[1] == :[] # node['foo']['bar'] scenario
              add_offense(sub_node.receiver.node_parts.first.loc.selector, severity: :warning)
            end
          end
        end
      end
    end
  end
end
