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
        # Use ::File.exist?('/foo/bar') instead of the slower 'test -f /foo/bar' which requires shelling out
        #
        # @example
        #
        #   ### incorrect
        #   only_if 'test -f /bin/foo'
        #
        #   ### correct
        #   only_if { ::File.exist?('bin/foo') }
        #
        class ConditionalUsingTest < Base
          extend AutoCorrector

          MSG = "Use ::File.exist?('/foo/bar') instead of the slower 'test -f /foo/bar' which requires shelling out"
          RESTRICT_ON_SEND = [:not_if, :only_if].freeze

          def_node_matcher :resource_conditional?, <<~PATTERN
            (send nil? {:not_if :only_if} $str )
          PATTERN

          def on_send(node)
            resource_conditional?(node) do |conditional|
              return unless conditional.value.match?(/^test -[ef] \S*$/)
              add_offense(node, severity: :refactor) do |corrector|
                new_string = "{ ::File.exist?('#{conditional.value.match(/^test -[ef] (\S*)$/)[1]}') }"
                corrector.replace(conditional, new_string)
              end
            end
          end
        end
      end
    end
  end
end
