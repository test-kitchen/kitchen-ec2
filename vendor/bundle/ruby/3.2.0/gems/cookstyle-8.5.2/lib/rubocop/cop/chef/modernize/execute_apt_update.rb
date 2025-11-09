# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software, Inc.
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
        # Instead of using the execute resource to run the `apt-get update` use Chef Infra Client's built-n apt_update resource which is available in Chef Infra Client 12.7 and later.
        #
        # @example
        #
        #   ### incorrect
        #   execute 'apt-get update'
        #
        #   execute 'Apt all the apt cache' do
        #     command 'apt-get update'
        #   end
        #
        #   execute 'some execute resource' do
        #     notifies :run, 'execute[apt-get update]', :immediately
        #   end
        #
        #   ### correct
        #   apt_update
        #
        #   apt_update 'update apt cache'
        #
        #   execute 'some execute resource' do
        #     notifies :update, 'apt_update[update apt cache]', :immediately
        #   end
        #
        class ExecuteAptUpdate < Base
          extend AutoCorrector

          MSG = 'Use the apt_update resource instead of the execute resource to run an apt-get update package cache update'
          RESTRICT_ON_SEND = [:execute, :notifies, :subscribes, :command].freeze

          def_node_matcher :execute_apt_update?, <<-PATTERN
            (send nil? :execute (str { "apt-get update" "apt-get update -y" "apt-get -y update" }))
          PATTERN

          def_node_matcher :notification_property?, <<-PATTERN
            (send nil? {:notifies :subscribes} (sym _) $(...) (sym _))
          PATTERN

          def_node_matcher :execute_command?, <<-PATTERN
            (send nil? :command $str)
          PATTERN

          def on_send(node)
            execute_apt_update?(node) do
              add_offense(node, severity: :refactor)
            end

            notification_property?(node) do |val|
              add_offense(val, severity: :refactor) if val.str_content&.start_with?('execute[apt-get update]')
            end

            execute_command?(node) do |val|
              add_offense(node, severity: :refactor) if val.str_content == 'apt-get update'
            end
          end
        end
      end
    end
  end
end
