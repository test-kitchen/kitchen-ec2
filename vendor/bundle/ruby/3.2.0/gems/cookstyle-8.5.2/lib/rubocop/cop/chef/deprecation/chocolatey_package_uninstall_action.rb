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
      module Deprecations
        # Use the `:remove` action in the `chocolatey_package` resource instead of `:uninstall` which was removed in Chef Infra Client 14+.
        #
        # @example
        #
        #   ### incorrect
        #   chocolatey_package 'nginx' do
        #     action :uninstall
        #   end
        #
        #   ### correct
        #   chocolatey_package 'nginx' do
        #     action :remove
        #   end
        #
        class ChocolateyPackageUninstallAction < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = 'Use the :remove action in the chocolatey_package resource instead of :uninstall which was removed in Chef Infra Client 14+'

          def on_block(node)
            match_property_in_resource?(:chocolatey_package, 'action', node) do |choco_action|
              choco_action.arguments.each do |action|
                next unless action.source == ':uninstall'
                add_offense(action, severity: :warning) do |corrector|
                  corrector.replace(action, ':remove')
                end
              end
            end
          end
        end
      end
    end
  end
end
