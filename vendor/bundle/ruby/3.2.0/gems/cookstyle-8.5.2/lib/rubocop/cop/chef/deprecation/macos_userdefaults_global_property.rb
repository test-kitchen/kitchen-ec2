# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
        # The `global` property in the macos_userdefaults resource was deprecated in Chef Infra Client 16.3. This property was never properly implemented and caused failures under many conditions. Omitting the `domain` property will now set global defaults.
        #
        # @example
        #
        #   ### incorrect
        #   macos_userdefaults 'set a value' do
        #     global true
        #     key 'key'
        #     value 'value'
        #   end
        #
        #   ### correct
        #   macos_userdefaults 'set a value' do
        #     key 'key'
        #     value 'value'
        #   end
        #
        class MacosUserdefaultsGlobalProperty < Base
          extend TargetChefVersion
          include RangeHelp
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          minimum_target_chef_version '16.3'

          MSG = 'The `global` property in the macos_userdefaults resource was deprecated in Chef Infra Client 16.3. Omitting the `domain` property will now set global defaults.'

          def on_block(node)
            match_property_in_resource?(:macos_userdefaults, 'global', node) do |global|
              add_offense(global.loc.expression, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: global.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
