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
        # The launchd resource's hash property was renamed to plist_hash in Chef Infra Client 13+ to avoid conflicts with Ruby's hash class.
        #
        # @example
        #
        #   ### incorrect
        #   launchd 'foo' do
        #     hash foo: 'bar'
        #   end
        #
        #   ### correct
        #   launchd 'foo' do
        #     plist_hash foo: 'bar'
        #   end
        #
        class LaunchdDeprecatedHashProperty < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.19'

          MSG = "The launchd resource's hash property was renamed to plist_hash in Chef Infra Client 13+ to avoid conflicts with Ruby's hash class."

          def on_block(node)
            match_property_in_resource?(:launchd, 'hash', node) do |offense|
              add_offense(offense.loc.expression, severity: :warning) do |corrector|
                corrector.replace(offense.loc.expression, offense.loc.expression.source.gsub(/^hash/, 'plist_hash'))
              end
            end
          end
        end
      end
    end
  end
end
