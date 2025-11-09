# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # Don't use the deprecated ChefSpec Coverage report functionality in your specs. This feature has been removed as coverage reports encourage cookbook authors to write ineffective specs. Focus on testing your logic instead of achieving 100% code coverage.
        #
        # @example
        #
        #   ### incorrect
        #
        #   at_exit { ChefSpec::Coverage.report! }
        #
        class ChefSpecCoverageReport < Base
          extend AutoCorrector
          MSG = "Don't use the deprecated ChefSpec coverage report functionality in your specs."

          def_node_matcher :coverage_reporter?, <<-PATTERN
          (block (send nil? :at_exit ) (args) (send (const (const nil? :ChefSpec) :Coverage) :report!))
          PATTERN

          def on_block(node)
            coverage_reporter?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(node)
              end
            end
          end
        end
      end
    end
  end
end
