# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
# Author:: Scott Vidmar (<svidmar@chef.io>)
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
      module Effortless
        # Chef Vault is not supported in the Effortless pattern, so usage of Chef Vault must be shifted to another secrets management solution before leveraging the Effortless pattern.
        #
        # @example
        #
        #   ### incorrect
        #   require 'chef-vault'
        #
        #   ### incorrect
        #   ChefVault::Item
        #
        #   ### incorrect
        #   include_recipe 'chef-vault'
        #
        #   ### incorrect
        #   chef_gem 'chef-vault'
        #
        #   ### incorrect
        #   chef_vault_item_for_environment(arg, arg1)
        #
        #   ### incorrect
        #   chef_vault_item(arg, arg1)
        #
        class ChefVaultUsed < Base
          MSG = 'Chef Vault usage is not supported in the Effortless pattern'
          RESTRICT_ON_SEND = [:chef_vault_item,
                              :chef_vault_item_for_environment,
                              :include_recipe,
                              :require,
                              :chef_gem].freeze

          def_node_matcher :require?, <<-PATTERN
            (send nil? { :require :include_recipe :chef_gem }
              (str "chef-vault"))
          PATTERN

          def_node_matcher :vault_const?, <<-PATTERN
            (const
              (const nil? :ChefVault)
              :Item)
          PATTERN

          def_node_matcher :chef_vault_item_for_environment?, <<-PATTERN
            (send nil? :chef_vault_item_for_environment _ _)
          PATTERN

          def_node_matcher :chef_vault_item?, <<-PATTERN
            (send nil? :chef_vault_item _ _)
          PATTERN

          def on_send(node)
            return unless require?(node) ||
                          chef_vault_item_for_environment?(node) ||
                          chef_vault_item?(node)
            add_offense(node.loc.expression, severity: :refactor)
          end

          def on_const(node)
            vault_const?(node) do
              add_offense(node.loc.expression, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
