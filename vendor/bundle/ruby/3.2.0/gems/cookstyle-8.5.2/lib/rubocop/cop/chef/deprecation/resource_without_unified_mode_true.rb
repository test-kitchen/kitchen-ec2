# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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
        # Chef Infra Client 15.3 and later include a new Unified Mode that simplifies the execution of resources by replace the traditional compile and converge phases with a single phase. Unified mode simplifies writing advanced resources and avoids confusing errors that often occur when mixing ruby and Chef Infra resources. Chef Infra Client 17.0 and later will begin warning that `unified_mode true` should be set in all resources to validate that they will continue to function in Chef Infra Client 18.0 (April 2022) when Unified Mode becomes the default.
        #
        # @example
        #
        #  ### incorrect
        #   resource_name :foo
        #   provides :foo
        #
        #   action :create do
        #     # some action code
        #   end
        #
        #  ### correct
        #   resource_name :foo
        #   provides :foo
        #   unified_mode true
        #
        #   action :create do
        #     # some action code
        #   end
        #
        class ResourceWithoutUnifiedTrue < Base
          include RangeHelp
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '15.3'

          MSG = 'Set `unified_mode true` in Chef Infra Client 15.3+ custom resources to ensure they work correctly in Chef Infra Client 18 (April 2022) when Unified Mode becomes the default.'

          def_node_search :unified_mode?, '(send nil? :unified_mode ...)'
          def_node_search :resource_name, '(send nil? :resource_name ...)'
          def_node_search :provides, '(send nil? :provides ...)'

          def on_new_investigation
            # gracefully fail if the resource is empty
            return if processed_source.ast.nil?

            # Using range similar to RuboCop::Cop::Naming::Filename (file_name.rb)
            return if unified_mode?(processed_source.ast)
            range = source_range(processed_source.buffer, 1, 0)
            add_offense(range, severity: :refactor) do |corrector|
              insert_below_provides(corrector) || insert_below_resource_name(corrector)
            end
          end

          def insert_below_provides(corrector)
            provides_ast = provides(processed_source.ast).first
            if provides_ast
              corrector.insert_after(provides_ast, "\nunified_mode true")
              true
            end
          end

          def insert_below_resource_name(corrector)
            resource_name_ast = resource_name(processed_source.ast).first
            if resource_name_ast
              corrector.insert_after(resource_name_ast, "\nunified_mode true")
              true
            end
          end
        end
      end
    end
  end
end
