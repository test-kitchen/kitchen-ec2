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
      module Modernize
        # Use the Chocolatey resources built into Chef Infra Client instead of shelling out to the choco command
        #
        # @example
        #
        #   ### incorrect
        #   execute 'install package foo' do
        #     command "choco install --source=artifactory \"foo\" -y --no-progress --ignore-package-exit-codes"
        #   end
        #
        #  powershell_script 'add artifactory choco source' do
        #    code "choco source add -n=artifactory -s='https://mycorp.jfrog.io/mycorp/api/nuget/chocolatey-remote' -u foo -p bar"x
        #    not_if 'choco source list | findstr artifactory'
        #  end
        #
        class ShellOutToChocolatey < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Use the Chocolatey resources built into Chef Infra Client instead of shelling out to the choco command'

          def on_block(node)
            match_property_in_resource?(:powershell_script, 'code', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              next unless property_data && property_data.match?(/^choco /i)
              add_offense(node, severity: :refactor)
            end

            match_property_in_resource?(:execute, 'command', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              next unless property_data && property_data.match?(/^choco /i)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
