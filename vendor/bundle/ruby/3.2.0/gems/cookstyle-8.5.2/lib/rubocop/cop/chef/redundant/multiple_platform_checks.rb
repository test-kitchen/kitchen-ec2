# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
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
      module RedundantCode
        # You can pass multiple values to the platform? and platform_family? helpers instead of calling the helpers multiple times.
        #
        # @example
        #
        #   ### incorrect
        #   platform?('redhat') || platform?('ubuntu')
        #   platform_family?('debian') || platform_family?('rhel')
        #
        #   ### correct
        #   platform?('redhat', 'ubuntu')
        #   platform_family?('debian', 'rhel')
        #
        class MultiplePlatformChecks < Base
          extend AutoCorrector

          MSG = 'You can pass multiple values to the platform? and platform_family? helpers instead of calling the helpers multiple times.'

          def_node_matcher :or_platform_helpers?, <<-PATTERN
            (or (send nil? ${:platform? :platform_family?} $_ )* )
          PATTERN

          def on_or(node)
            or_platform_helpers?(node) do |helpers, plats|
              # if the helper types were the same it's an offense, but platform_family?('rhel') || platform?('ubuntu') is legit
              return unless helpers.uniq.size == 1

              add_offense(node, severity: :refactor) do |corrector|
                new_string = "#{helpers.first}(#{plats.map(&:source).join(', ')})"
                corrector.replace(node, new_string)
              end
            end
          end
        end
      end
    end
  end
end
