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
        # The Ohai default recipe previously allowed a user to ship custom Ohai plugins to a system by including them in a directory in the Ohai cookbook. This functionality was replaced with the ohai_plugin resource, which should be used instead as it doesn't require forking the ohai cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'ohai::default'
        #   include_recipe 'ohai'
        #
        class IncludingOhaiDefaultRecipe < Base
          MSG = "Use the ohai_plugin resource to ship custom Ohai plugins instead of using the ohai::default recipe. If you're not shipping custom Ohai plugins, then you can remove this recipe entirely"
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :ohai_recipe_usage?, <<-PATTERN
            (send nil? :include_recipe (str {"ohai" "ohai::default"}))
          PATTERN

          def on_send(node)
            ohai_recipe_usage?(node) do
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
