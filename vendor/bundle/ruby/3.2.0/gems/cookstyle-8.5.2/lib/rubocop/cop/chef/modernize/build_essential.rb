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
      module Modernize
        # Use the build_essential resource from the build-essential cookbook 5.0+ or Chef Infra Client 14+ instead of using the build-essential::default recipe.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'build-essential'
        #   include_recipe 'build-essential::default'
        #   include_recipe 'build-essential'
        #
        #   ### correct
        #   build_essential 'install compilation tools'
        #
        class UseBuildEssentialResource < Base
          extend AutoCorrector

          MSG = 'Use the build_essential resource instead of the legacy build-essential recipe. This resource ships in the build-essential cookbook v5.0+ and is built into Chef Infra Client 14+'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :build_essential_recipe_usage?, <<-PATTERN
            (send nil? :include_recipe (str {"build-essential" "build-essential::default"}))
          PATTERN

          def on_send(node)
            build_essential_recipe_usage?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "build_essential 'install compilation tools'")
              end
            end
          end
        end
      end
    end
  end
end
