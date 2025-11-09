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
        # Use the windows_feature resource built into Chef Infra Client 14+ instead of the powershell_script resource to run Install-WindowsFeature or Add-WindowsFeature
        #
        # @example
        #
        #   ### incorrect
        #   powershell_script 'Install Feature' do
        #     code 'Install-WindowsFeature -Name "Net-framework-Core"'
        #   end
        #
        #  ### correct
        #  windows_feature 'Net-framework-Core' do
        #    action :install
        #    install_method :windows_feature_powershell
        #  end
        #
        class PowershellInstallWindowsFeature < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '14.0'

          MSG = 'Use the windows_feature resource built into Chef Infra Client 14+ instead of using Install-WindowsFeature or Add-WindowsFeature in a powershell_script resource'

          def on_block(node)
            match_property_in_resource?(:powershell_script, 'code', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              return unless property_data && property_data.match?(/^(install|add)-windowsfeature\s/i)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
