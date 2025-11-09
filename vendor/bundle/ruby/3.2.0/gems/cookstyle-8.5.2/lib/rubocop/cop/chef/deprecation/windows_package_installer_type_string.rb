# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # In Chef Infra Client 13 and later the `windows_package` resource's `installer_type` property must be a symbol.
        #
        # @example
        #
        #   ### incorrect
        #   windows_package 'AppveyorDeploymentAgent' do
        #     source 'https://www.example.com/appveyor.msi'
        #     installer_type 'msi'
        #     options "/quiet /qn /norestart /log install.log"
        #   end
        #
        #   ### correct
        #   windows_package 'AppveyorDeploymentAgent' do
        #     source 'https://www.example.com/appveyor.msi'
        #     installer_type :msi
        #     options "/quiet /qn /norestart /log install.log"
        #   end
        #
        class WindowsPackageInstallerTypeString < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = "In Chef Infra Client 13 and later the `windows_package` resource's `installer_type` property must be a symbol."

          def on_block(node)
            match_property_in_resource?(:windows_package, 'installer_type', node) do |offense|
              return unless offense.arguments.one? # we can only analyze simple string args
              return unless offense.arguments.first.str_type? # anything else is fine

              add_offense(offense, severity: :warning) do |corrector|
                corrector.replace(offense.arguments.first.source_range, ":#{offense.arguments.first.value}")
              end
            end
          end
        end
      end
    end
  end
end
