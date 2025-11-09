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
        # Use 'shell_out!' instead of the legacy 'run_command' or 'run_command_with_systems_locale' helpers for shelling out. The run_command helper was removed in Chef Infra Client 13.
        #
        # @example
        #
        #   ### incorrect
        #   require 'chef/mixin/command'
        #   include Chef::Mixin::Command
        #
        #   run_command('/bin/foo')
        #   run_command_with_systems_locale('/bin/foo')
        #
        #   ### correct
        #   shell_out!('/bin/foo')
        #
        class UsesRunCommandHelper < Base
          MSG = "Use 'shell_out!' instead of the legacy 'run_command' or 'run_command_with_systems_locale' helpers for shelling out. The run_command helper was removed in Chef Infra Client 13."
          RESTRICT_ON_SEND = [:require, :run_command, :run_command_with_systems_locale, :include].freeze

          def_node_matcher :calls_run_command?, '(send nil? {:run_command :run_command_with_systems_locale} ...)'
          def_node_matcher :require_mixin_command?, '(send nil? :require (str "chef/mixin/command"))'
          def_node_matcher :include_mixin_command?, '(send nil? :include (const (const (const nil? :Chef) :Mixin) :Command))'

          def_node_search :defines_run_command?, '(def {:run_command :run_command_with_systems_locale} ...)'

          def on_send(node)
            calls_run_command?(node) do
              add_offense(node, severity: :warning) unless defines_run_command?(processed_source.ast)
            end

            require_mixin_command?(node) do
              add_offense(node, severity: :warning)
            end

            include_mixin_command?(node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
