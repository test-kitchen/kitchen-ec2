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
        # Chef Infra Client 16 and later a legacy HWRP resource must use `provides` to define how the resource is called in recipes or other resources. To maintain compatibility with Chef Infra Client < 16 use both `resource_name` and `provides`.
        #
        # @example
        #
        #   ### incorrect
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        #   ### incorrect
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         resource_name :ulimit_rule
        #
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        #  ### correct when Chef Infra Client < 15 (but compatible with 16+ as well)
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         resource_name :ulimit_rule
        #         provides :ulimit_rule
        #
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        #  ### correct when Chef Infra Client 16+
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         provides :ulimit_rule
        #
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        #  # better
        #  Convert your legacy HWRPs to custom resources
        #
        class HWRPWithoutProvides < Base
          extend AutoCorrector

          MSG = 'In Chef Infra Client 16 and later a legacy HWRP resource must use `provides` to define how the resource is called in recipes or other resources. To maintain compatibility with Chef Infra Client < 16 use both `resource_name` and `provides`.'

          def_node_matcher :HWRP?, <<-PATTERN
          (class
            (const nil? :Chef) nil?
            (class
              (const nil? :Resource) nil?
              $(class
                (const nil? ... )
                (const
                  (const nil? :Chef) :Resource)
                  (begin ... ))))
          PATTERN

          def_node_search :provides, '(send nil? :provides (sym $_) ...)'
          def_node_search :resource_name_ast, '$(send nil? :resource_name ...)'
          def_node_search :resource_name, '(send nil? :resource_name (sym $_))'

          def on_class(node)
            return if has_provides?
            HWRP?(node) do |inherit|
              add_offense(inherit, severity: :warning) do |corrector|
                resource_name_ast(node) do |ast_match|
                  # build a new string to add after that includes the new line and the proper indentation
                  new_string = "\n" + ast_match.source.dup.gsub('resource_name', 'provides').prepend(' ' * indentation(ast_match))
                  corrector.insert_after(ast_match.source_range, new_string)
                end
              end
            end
          end

          def has_provides?
            provides_ast = provides(processed_source.ast)
            return false if provides_ast.none?

            resource_ast = resource_name(processed_source.ast)

            # if no resource ast then resource_name, but not provides
            # else make sure the provides matches the resource name
            resource_ast.none? || provides_ast.include?(resource_ast.first)
          end

          def indentation(node)
            node.source_range.source_line =~ /\S/
          end
        end
      end
    end
  end
end
