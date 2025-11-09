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
      module Deprecations
        # The supports property was removed in Chef Infra Client 13 in favor of individual 'manage_home' and 'non_unique' properties.
        #
        # @example
        #
        #   ### incorrect
        #   user "betty" do
        #     supports({
        #       manage_home: true,
        #       non_unique: true
        #     })
        #   end
        #
        #   user 'betty' do
        #     supports :manage_home => true
        #   end
        #
        #   ### correct
        #   user "betty" do
        #     manage_home true
        #     non_unique true
        #   end
        #
        class UserDeprecatedSupportsProperty < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = "The supports property was removed in Chef Infra Client 13 in favor of individual 'manage_home' and 'non_unique' properties."

          def on_block(node)
            match_property_in_resource?(:user, 'supports', node) do |property|
              add_offense(property, severity: :warning) do |corrector|
                new_text = []

                property.arguments.first.each_pair do |k, v|
                  # account for a strange edge case where the person incorrectly makes "manage_home a method
                  # the code would be broken, but without this handling cookstyle would explode
                  key_value = (k.send_type? && k.method?(:manage_home)) ? 'manage_home' : k.value

                  new_text << "#{key_value} #{v.source}"
                end

                corrector.replace(property, new_text.join("\n  "))
              end
            end
          end
        end
      end
    end
  end
end
