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
        # Don't depend on the `openssl` cookbook which was made obsolete by Chef Infra Client 14.4. All `openssl_*` resources are now included directly in Chef Infra Client.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'openssl'
        #
        class DependsOnOpensslCookbook < Base
          extend AutoCorrector
          extend TargetChefVersion
          include RangeHelp

          minimum_target_chef_version '14.4'

          MSG = "Don't depend on the `openssl` cookbook which was made obsolete by Chef Infra Client 14.4. All `openssl_*` resources are now included directly in Chef Infra Client."
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :legacy_depends?, <<-PATTERN
            (send nil? :depends (str "openssl") ... )
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
