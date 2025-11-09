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
      module Modernize
        # Don't depend on cookbooks made obsolete by Chef Infra Client 15.0+. These community cookbooks contain resources that are now included in Chef Infra Client itself.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'libarchive'
        #   depends 'windows_dns'
        #   depends 'windows_uac'
        #   depends 'windows_dfs'
        #
        class UnnecessaryDependsChef15 < Base
          extend AutoCorrector
          extend TargetChefVersion
          include RangeHelp

          minimum_target_chef_version '15.0'

          MSG = "Don't depend on cookbooks made obsolete by Chef Infra Client 15.0+. These community cookbooks contain resources that are now included in Chef Infra Client itself."
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :legacy_depends?, <<-PATTERN
            (send nil? :depends (str {"libarchive" "windows_dns" "windows_uac" "windows_dfs"}) ... )
          PATTERN

          def on_send(node)
            legacy_depends?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
