# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software, Inc.
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
        # Don't include the deprecated yum DNF compatibility recipe, which is no longer necessary
        # as Chef Infra Client includes DNF package support
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'yum::dnf_yum_compat'
        #
        class IncludingYumDNFCompatRecipe < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'Do not include the deprecated yum::dnf_yum_compat default recipe to install yum on dnf systems. Chef Infra Client now includes built in support for DNF packages.'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :yum_dnf_compat_recipe_usage?, <<-PATTERN
            (send nil? :include_recipe (str "yum::dnf_yum_compat"))
          PATTERN

          def on_send(node)
            yum_dnf_compat_recipe_usage?(node) do
              node = node.parent if node.parent&.conditional? && node.parent&.single_line?
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
