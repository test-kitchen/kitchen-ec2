# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software, Inc.
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
        # The `sudo` resource in the sudo cookbook 5.0 (2018) or Chef Infra Client 14 and later have replaced the existing `:install` and `:remove` actions with `:create` and `:delete` actions to better match other resources in Chef Infra.
        #
        # @example
        #
        #   ### incorrect
        #   sudo 'admins' do
        #     users 'bob'
        #     groups 'sysadmins, superusers'
        #     action :remove
        #   end
        #
        #   ### correct
        #   sudo 'admins' do
        #     users 'bob'
        #     groups 'sysadmins, superusers'
        #     action :delete
        #   end
        #
        class DeprecatedSudoActions < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '14.0'

          MSG = 'The `sudo` resource in the sudo cookbook 5.0 (2018) or Chef Infra Client 14 and later have replaced the existing `:install` and `:remove` actions with `:create` and `:delete` actions to better match other resources in Chef Infra.'

          def on_block(node)
            match_property_in_resource?(:sudo, 'action', node) do |prop_node|
              next unless prop_node.arguments.first.sym_type?
              next unless [s(:sym, :install), s(:sym, :remove)].include?(prop_node.arguments.first)

              add_offense(prop_node, severity: :warning) do |corrector|
                corrector.replace(prop_node, prop_node.source
                  .gsub('install', 'create')
                  .gsub('remove', 'delete'))
              end
            end
          end
        end
      end
    end
  end
end
