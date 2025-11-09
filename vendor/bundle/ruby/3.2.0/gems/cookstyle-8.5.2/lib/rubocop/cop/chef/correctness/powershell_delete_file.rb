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
      module Correctness
        # Use the `file` or `directory` resources built into Chef Infra Client with the :delete action to remove files/directories instead of using Remove-Item in a powershell_script resource
        #
        # @example
        #
        #   ### incorrect
        #   powershell_script 'Cleanup old files' do
        #     code 'Remove-Item C:\Windows\foo\bar.txt'
        #     only_if { ::File.exist?('C:\\Windows\\foo\\bar.txt') }
        #   end
        #
        #  ### correct
        #  file 'C:\Windows\foo\bar.txt' do
        #    action :delete
        #  end
        #
        class PowershellScriptDeleteFile < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Use the `file` or `directory` resources built into Chef Infra Client with the :delete action to remove files/directories instead of using Remove-Item in a powershell_script resource'

          def on_block(node)
            match_property_in_resource?(:powershell_script, 'code', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              return unless property_data && property_data.match?(/^remove-item/i) &&
                            !property_data.include?('*')
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
