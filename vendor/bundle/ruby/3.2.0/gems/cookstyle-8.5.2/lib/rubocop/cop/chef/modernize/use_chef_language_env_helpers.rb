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
        # Chef Infra Client 15.5 and later include a large number of new helpers in the Chef Infra Language to simplify checking the system configuration in recipes and resources. These should be used when possible over more complex attributes or ENV var comparisons.
        #
        # @example
        #
        #   ### incorrect
        #   ENV['CI']
        #   ENV['TEST_KITCHEN']
        #
        #   ### correct
        #   ci?
        #   kitchen?
        #
        class UseChefLanguageEnvHelpers < Base
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '15.5'

          RESTRICT_ON_SEND = [:[]].freeze

          def_node_matcher :env?, <<-PATTERN
            (send
              (const nil? :ENV) :[]
              (str ${"TEST_KITCHEN" "CI"}))
          PATTERN

          def on_send(node)
            env?(node) do |env_value|
              # we don't handle .nil? checks yet so just skip them
              next if node.parent.send_type? && node.parent.method?(:nil?)

              case env_value
              when 'CI'
                add_offense(node, message: 'Chef Infra Client 15.5 and later include a helper `ci?` that should be used to see if the `CI` env var is set.', severity: :refactor) do |corrector|
                  corrector.replace(node, 'ci?')
                end
              when 'TEST_KITCHEN'
                add_offense(node, message: 'Chef Infra Client 15.5 and later include a helper `kitchen?` that should be used to see if the `TEST_KITCHEN` env var is set.', severity: :refactor) do |corrector|
                  corrector.replace(node, 'kitchen?')
                end
              end
            end
          end
        end
      end
    end
  end
end
