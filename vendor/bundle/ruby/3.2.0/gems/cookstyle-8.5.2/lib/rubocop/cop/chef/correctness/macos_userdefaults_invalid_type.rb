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
      module Correctness
        # The macos_userdefaults resource prior to Chef Infra Client 16.3 would silently continue if invalid types were passed resulting in unexpected behavior. Valid values are: "array", "bool", "dict", "float", "int", and "string".
        #
        # @example
        #
        #   ### incorrect
        #   macos_userdefaults 'set a value' do
        #     global true
        #     key 'key'
        #     type 'boolean'
        #   end
        #
        #   ### correct
        #   macos_userdefaults 'set a value' do
        #     global true
        #     key 'key'
        #     type 'bool'
        #   end
        #
        class MacosUserdefaultsInvalidType < Base
          include RuboCop::Chef::CookbookHelpers
          extend RuboCop::Cop::AutoCorrector

          VALID_VALUES = %w(array bool dict float int string).freeze
          INVALID_VALUE_MAP = {
            'boolean' => 'bool',
            'str' => 'string',
            'integer' => 'int',
          }.freeze

          MSG = 'The macos_userdefaults resource prior to Chef Infra Client 16.3 would silently continue if invalid types were passed resulting in unexpected behavior. Valid values are: "array", "bool", "dict", "float", "int", and "string".'

          def on_block(node)
            match_property_in_resource?(:macos_userdefaults, 'type', node) do |type|
              type_val = method_arg_ast_to_string(type)
              return if VALID_VALUES.include?(type_val)
              add_offense(type, severity: :refactor) do |corrector|
                next unless INVALID_VALUE_MAP[type_val]
                corrector.replace(type, "type '#{INVALID_VALUE_MAP[type_val]}'")
              end
            end
          end
        end
      end
    end
  end
end
