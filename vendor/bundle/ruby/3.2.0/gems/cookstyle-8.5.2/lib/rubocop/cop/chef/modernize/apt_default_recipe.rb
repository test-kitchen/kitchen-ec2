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
        # For many users the apt::default cookbook is used only to update apt's package cache. Chef Infra Client 12.7 and later include an apt_update resource which should be used to perform this instead. Keep in mind that some users will want to stick with the apt::default recipe as it also installs packages necessary for using https repositories on Debian systems and manages some configuration files.
        #
        # @example
        #
        #   ### incorrect
        #   include_recipe 'apt::default'
        #   include_recipe 'apt'
        #
        #   ### correct
        #   apt_update
        #
        class IncludingAptDefaultRecipe < Base
          extend TargetChefVersion

          minimum_target_chef_version '12.7'

          MSG = 'Do not include the Apt default recipe to update package cache. Instead use the apt_update resource, which is built into Chef Infra Client 12.7 and later.'
          RESTRICT_ON_SEND = [:include_recipe].freeze

          def_node_matcher :apt_recipe_usage?, <<-PATTERN
            (send nil? :include_recipe (str {"apt" "apt::default"}))
          PATTERN

          def on_send(node)
            apt_recipe_usage?(node) do
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
