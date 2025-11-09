# frozen_string_literal: true
#
# Copyright:: 2020-2021, Chef Software, Inc.
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
        # Chef Infra Client 15.0 and later includes a windows_uac resource that should be used to set Windows UAC values instead of setting registry keys directly.
        #
        # @example
        #
        #   ### incorrect
        #   registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
        #     values [{ name: 'EnableLUA', type: :dword, data: 0 },
        #             { name: 'PromptOnSecureDesktop', type: :dword, data: 0 },
        #             { name: 'ConsentPromptBehaviorAdmin', type: :dword, data: 0 },
        #            ]
        #     action :create
        #   end
        #
        #   ### correct
        #   windows_uac 'Set Windows UAC settings' do
        #     enable_uac false
        #     prompt_on_secure_desktop true
        #     consent_behavior_admins :no_prompt
        #   end
        #
        class WindowsRegistryUAC < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '15.0'

          MSG = 'Chef Infra Client 15.0 and later includes a windows_uac resource that should be used to set Windows UAC values instead of setting registry keys directly.'
          RESTRICT_ON_SEND = [:registry_key].freeze
          VALID_VALUES = %w(EnableLUA ValidateAdminCodeSignatures PromptOnSecureDesktop ConsentPromptBehaviorAdmin ConsentPromptBehaviorUser EnableInstallerDetection).freeze

          # block registry_key resources
          def on_block(node)
            return unless node.method?(:registry_key)
            return unless correct_key?(node)
            return unless uac_supported_values?(node)
            add_offense(node, severity: :refactor)
          end

          # make sure the values passed are all the ones in the uac resource
          # this key has other values we don't support in the windows_uac resource
          def uac_supported_values?(node)
            match_property_in_resource?(:registry_key, 'values', node) do |val_prop|
              return false unless val_prop&.arguments.first.array_type? # make sure values isn't being passed a variable or method
              val_prop.arguments.first.each_value do |array|
                array.each_pair do |key, value|
                  if key == s(:sym, :name)
                    return false unless value.str_type? # make sure it isn't being a variable or method that we can't parse
                    return false unless VALID_VALUES.include?(value.value)
                  end
                end
              end
            end
            true
          end

          # make sure the registry_key resource is running against the correct key
          # check the block name and the key property (registry_key's name property)
          def correct_key?(node)
            return true if node.send_node.arguments.first.source.match?(/(HKLM|HKEY_LOCAL_MACHINE)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System/i)

            match_property_in_resource?(:registry_key, 'key', node) do |key_prop|
              property_data = method_arg_ast_to_string(key_prop)
              return true if property_data && property_data.match?(/(HKLM|HKEY_LOCAL_MACHINE)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System/i)
            end
            false
          end
        end
      end
    end
  end
end
