# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # Use the built-in `shell_out` helper available in Chef Infra Client 12.11+ instead of calling `Mixlib::ShellOut.new('foo').run_command`.
        #
        # @example
        #
        #   ### incorrect
        #   Mixlib::ShellOut.new('foo').run_command
        #
        #   ### correct
        #   shell_out('foo')
        #
        class ShellOutHelper < Base
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '12.11'

          MSG = "Use the built-in `shell_out` helper available in Chef Infra Client 12.11+ instead of calling `Mixlib::ShellOut.new('foo').run_command`."
          RESTRICT_ON_SEND = [:run_command].freeze

          def_node_matcher :mixlib_shellout_run_cmd?, <<-PATTERN
          (send
            (send
              (const
                (const nil? :Mixlib) :ShellOut) :new
              $(...)) :run_command)
          PATTERN

          def on_send(node)
            mixlib_shellout_run_cmd?(node) do |cmd|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "shell_out(#{cmd.source})")
              end
            end
          end
        end
      end
    end
  end
end
