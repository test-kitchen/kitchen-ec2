# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # Don't use deprecated Mixins no longer included in Chef Infra Client 14 and later.
        #
        # @example
        #
        #   ### incorrect
        #   include Chef::Mixin::LanguageIncludeAttribute
        #   include Chef::Mixin::RecipeDefinitionDSLCore
        #   include Chef::Mixin::LanguageIncludeRecipe
        #   include Chef::Mixin::Language
        #   include Chef::DSL::Recipe::FullDSL
        #   require 'chef/mixin/language'
        #   require 'chef/mixin/language_include_attribute'
        #   require 'chef/mixin/language_include_recipe'
        #
        class UsesDeprecatedMixins < Base
          include RangeHelp
          extend AutoCorrector

          MSG = "Don't use deprecated Mixins no longer included in Chef Infra Client 14 and later."
          RESTRICT_ON_SEND = [:include, :require].freeze

          def_node_matcher :deprecated_mixin?, <<-PATTERN
            (send nil? :include (const (const (const nil? :Chef) :Mixin) { :Language :LanguageIncludeAttribute :RecipeDefinitionDSLCore :LanguageIncludeRecipe }))
          PATTERN

          def_node_matcher :deprecated_dsl?, <<-PATTERN
            (send nil? :include (const (const (const (const nil? :Chef) :DSL) :Recipe) :FullDSL))
          PATTERN

          def_node_matcher :dsl_mixin_require?, <<-PATTERN
            (send nil? :require ( str {"chef/mixin/language" "chef/mixin/language_include_attribute" "chef/mixin/language_include_recipe"}))
          PATTERN

          def on_send(node)
            deprecated_mixin?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end

            deprecated_dsl?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end

            dsl_mixin_require?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
