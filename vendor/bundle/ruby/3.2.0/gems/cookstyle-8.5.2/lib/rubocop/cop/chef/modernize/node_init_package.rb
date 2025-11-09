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
        # Use node['init_package'] to check for systemd instead of reading the contents of '/proc/1/comm'
        #
        # @example
        #
        #   ### incorrect
        #   ::File.open('/proc/1/comm').gets.chomp == 'systemd'
        #   ::File.open('/proc/1/comm').chomp == 'systemd'
        #   File.open('/proc/1/comm').gets.chomp == 'systemd'
        #   File.open('/proc/1/comm').chomp == 'systemd'
        #   IO.read('/proc/1/comm').chomp == 'systemd'
        #   IO.read('/proc/1/comm').gets.chomp == 'systemd'
        #   ::IO.read('/proc/1/comm').chomp == 'systemd'
        #   ::IO.read('/proc/1/comm').gets.chomp == 'systemd'
        #   File.exist?('/proc/1/comm') && File.open('/proc/1/comm').chomp == 'systemd'
        #   only_if 'test -f /bin/systemctl && /bin/systemctl'
        #
        #   ### correct
        #   node['init_package'] == 'systemd'
        #   only_if { node['init_package'] == 'systemd' }
        #
        class NodeInitPackage < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = "Use node['init_package'] to check for systemd instead of reading the contents of '/proc/1/comm'"
          RESTRICT_ON_SEND = [:open, :read, :exist?, :==, :not_if, :only_if].freeze

          def_node_matcher :file_reads_proc_1_comm?, <<-PATTERN
            (send (const {(cbase) nil?} {:File :IO}) {:open :read} (str "/proc/1/comm"))
          PATTERN

          def_node_matcher :proc_1_comm_exists?, <<-PATTERN
            (send
              (const
                {(cbase) nil?} :File) :exist?
              (str "/proc/1/comm"))
          PATTERN

          def_node_matcher :compare_init_system?, <<-PATTERN
            (send
              (send {#file_reads_proc_1_comm? (send #file_reads_proc_1_comm? :gets) } :chomp)
                :== (str "systemd"))
          PATTERN

          def_node_matcher :file_systemd_conditional?, <<~PATTERN
            (send nil? {:not_if :only_if} $(str "test -f /bin/systemctl && /bin/systemctl"))
          PATTERN

          def on_send(node)
            compare_init_system?(node) do
              # if there's a ::File.exist?('/proc/1/comm') check first we want to match that as well
              node = node.parent if node.parent&.and_type? && proc_1_comm_exists?(node.parent.conditions.first)

              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "node['init_package'] == 'systemd'")
              end
            end

            file_systemd_conditional?(node) do |conditional|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(conditional, "{ node['init_package'] == 'systemd' }")
              end
            end
          end
        end
      end
    end
  end
end
