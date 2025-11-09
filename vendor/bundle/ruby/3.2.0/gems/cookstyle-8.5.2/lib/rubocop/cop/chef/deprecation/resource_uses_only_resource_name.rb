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
        # Starting with Chef Infra Client 16, using `resource_name` without also using `provides` will result in resource failures. Make sure to use both `resource_name` and `provides` to change the name of the resource. You can also omit `resource_name` entirely if the value set matches the name Chef Infra Client automatically assigns based on COOKBOOKNAME_FILENAME.
        #
        # @example
        #
        #   ### incorrect
        #   mycookbook/resources/myresource.rb:
        #   resource_name :mycookbook_myresource
        #
        class ResourceUsesOnlyResourceName < Base
          include RuboCop::Chef::CookbookHelpers
          include RangeHelp
          extend AutoCorrector

          MSG = 'Starting with Chef Infra Client 16, using `resource_name` without also using `provides` will result in resource failures. Make sure to use both `resource_name` and `provides` to change the name of the resource. You can also omit `resource_name` entirely if the value set matches the name Chef Infra Client automatically assigns based on COOKBOOKNAME_FILENAME.'
          RESTRICT_ON_SEND = [:resource_name].freeze

          def_node_matcher :resource_name?, '(send nil? :resource_name (sym $_ ))'

          def_node_search :cb_name_match, '(send nil? :name (str $_))'

          def_node_search :provides, '(send nil? :provides (sym $_) ...)'

          # determine the cookbook name either by parsing metadata.rb or by parsing metadata.json
          #
          # @return [String] the cookbook name
          def cookbook_name
            cb_path = File.expand_path(File.join(processed_source.file_path, '../..'))

            if File.exist?(File.join(cb_path, 'metadata.rb'))
              cb_metadata_ast = ProcessedSource.from_file(File.join(cb_path, 'metadata.rb'), @config.target_ruby_version).ast
              cb_name_match(cb_metadata_ast).first
            elsif File.exist?(File.join(cb_path, 'metadata.json')) # this exists only for supermarket files that lack metadata.rb
              JSON.parse(File.read(File.join(cb_path, 'metadata.json')))['name']
            end
          end

          # given a resource name make sure there's a provides that matches that name
          #
          # @return [TrueClass, FalseClass]
          def valid_provides?(resource_name)
            provides_ast = provides(processed_source.ast)
            return false unless provides_ast

            provides_ast.include?(resource_name)
          end

          def on_send(node)
            resource_name?(node) do |name|
              return if valid_provides?(name)
              add_offense(node, severity: :warning) do |corrector|
                if name.to_s == "#{cookbook_name}_#{File.basename(processed_source.path, '.rb')}"
                  corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
                else
                  corrector.insert_after(node.source_range, "\n#{node.source.gsub('resource_name', 'provides')}")
                end
              end
            end
          end
        end
      end
    end
  end
end
