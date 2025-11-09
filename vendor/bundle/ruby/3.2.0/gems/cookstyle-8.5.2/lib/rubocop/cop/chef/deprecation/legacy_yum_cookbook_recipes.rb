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
        # The Ohai default recipe previously allowed a user to ship custom Ohai plugins to a system by including them
        # in a directory in the Ohai cookbook. This functionality was replaced with the ohai_plugin resource, which
        # should be used instead as it doesn't require forking the ohai cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'yum::elrepo'
        #   include_recipe 'yum::epel'
        #   include_recipe 'yum::ius'
        #   include_recipe 'yum::remi'
        #   include_recipe 'yum::repoforge'
        #   include_recipe 'yum::yum'
        #
        class LegacyYumCookbookRecipes < Base
          MSG = 'The elrepo, epel, ius, remi, and repoforge recipes were split into their own cookbooks and the yum recipe was renamed to be default with the release of yum cookbook 3.0 (Dec 2013).'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :old_yum_recipe?, <<-PATTERN
            (send nil? :include_recipe (str {"yum::elrepo" "yum::epel" "yum::ius" "yum::remi" "yum::repoforge" "yum::yum"}))
          PATTERN

          def on_send(node)
            old_yum_recipe?(node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
