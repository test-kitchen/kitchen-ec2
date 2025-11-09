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
      module Modernize
        # The nokogiri gem ships in Chef Infra Client 12+ and does not need to be installed before being used
        #
        # @example
        #
        #   ### incorrect
        #   chef_gem 'nokogiri'
        #
        class ChefGemNokogiri < Base
          extend AutoCorrector
          include RangeHelp
          include RuboCop::Chef::CookbookHelpers

          MSG = 'The nokogiri gem ships in Chef Infra Client 12+ and does not need to be installed before being used.'
          RESTRICT_ON_SEND = [:chef_gem].freeze

          def_node_matcher :nokogiri_install?, <<-PATTERN
            (send nil? :chef_gem (str "nokogiri"))
          PATTERN

          def on_block(node)
            match_property_in_resource?(:chef_gem, 'package_name', node) do |pkg_name|
              return unless pkg_name.arguments&.first&.str_content == 'nokogiri'
              add_offense(node, severity: :refactor) do |corrector|
                node = node.parent if node.parent&.block_type? # make sure we get the whole block not just the method in the block
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end

          def on_send(node)
            nokogiri_install?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                node = node.parent if node.parent&.block_type? # make sure we get the whole block not just the method in the block
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
