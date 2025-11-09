# frozen_string_literal: true
#
# Copyright:: 2016, Chris Henry
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
      module Correctness
        # Use a service resource to start and stop services
        #
        # @example when command starts a service
        #
        #   ### incorrect
        #   command "/etc/init.d/mysql start"
        #   command "/sbin/service/memcached start"
        #
        class ServiceResource < Base
          MSG = 'Use a service resource to start and stop services'
          RESTRICT_ON_SEND = [:command].freeze

          def_node_matcher :execute_command?, <<-PATTERN
            (send nil? :command $str)
          PATTERN

          def on_send(node)
            execute_command?(node) do |command|
              if starts_service?(command)
                add_offense(command, severity: :refactor)
              end
            end
          end

          def starts_service?(cmd)
            cmd_str = cmd.to_s
            (cmd_str.include?('/etc/init.d') || ['service ', '/sbin/service ',
                                                 'start ', 'stop ', 'invoke-rc.d '].any? do |service_cmd|
               cmd_str.start_with?(service_cmd)
             end) && %w(start stop restart reload).any? { |a| cmd_str.include?(a) }
          end
        end
      end
    end
  end
end
