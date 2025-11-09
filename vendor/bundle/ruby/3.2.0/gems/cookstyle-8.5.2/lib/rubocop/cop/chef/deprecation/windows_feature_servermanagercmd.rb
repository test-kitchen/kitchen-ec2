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
      module Deprecations
        # The `windows_feature` resource no longer supports setting the `install_method` to `:servermanagercmd`. `:windows_feature_dism` or `:windows_feature_powershell` should be used instead.
        #
        # @example
        #
        #   ### incorrect
        #   windows_feature 'DHCP' do
        #     install_method :servermanagercmd
        #   end
        #
        #   ### correct
        #   windows_feature 'DHCP' do
        #     install_method :windows_feature_dism
        #   end
        #
        #   windows_feature 'DHCP' do
        #     install_method :windows_feature_powershell
        #   end
        #
        #   windows_feature_dism 'DHCP'
        #
        #   windows_feature_powershell 'DHCP'
        #
        class WindowsFeatureServermanagercmd < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'The `windows_feature` resource no longer supports setting the `install_method` to `:servermanagercmd`. `:windows_feature_dism` or `:windows_feature_powershell` should be used instead.'

          def on_block(node)
            match_property_in_resource?(:windows_feature, :install_method, node) do |prop_node|
              add_offense(prop_node, severity: :warning) if prop_node.source.include?(':servermanagercmd')
            end
          end
        end
      end
    end
  end
end
