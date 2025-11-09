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
        # PowerShell is already set as the default guard interpreter for `powershell_script` and `batch` resources in Chef Infra Client 13 and later and does not need to be specified.
        #
        # @example
        #
        #   ### incorrect
        #   powershell_script 'Create Directory' do
        #     code "New-Item -ItemType Directory -Force -Path C:\mydir"
        #     guard_interpreter :powershell_script
        #   end
        #
        #   batch 'Create Directory' do
        #     code "mkdir C:\mydir"
        #     guard_interpreter :powershell_script
        #   end
        #
        #   ### correct
        #   powershell_script 'Create Directory' do
        #     code "New-Item -ItemType Directory -Force -Path C:\mydir"
        #   end
        #
        #   batch 'Create Directory' do
        #     code "mkdir C:\mydir"
        #   end
        #
        class PowerShellGuardInterpreter < Base
          include RuboCop::Chef::CookbookHelpers
          include RangeHelp
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '13.0'

          MSG = 'PowerShell is already set as the default guard interpreter for `powershell_script` and `batch` resources in Chef Infra Client 13 and later and does not need to be specified.'

          def on_block(node)
            match_property_in_resource?(%i(powershell_script batch), 'guard_interpreter', node) do |interpreter|
              return unless interpreter.arguments.first.source == ':powershell_script'
              add_offense(interpreter, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: interpreter.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
