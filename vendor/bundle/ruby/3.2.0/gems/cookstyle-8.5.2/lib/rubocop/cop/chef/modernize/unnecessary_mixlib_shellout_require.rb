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
      module Modernize
        # Chef Infra Client 12.4+ includes mixlib/shellout automatically in resources and providers.
        #
        # @example
        #
        #   ### incorrect
        #   require 'mixlib/shellout'
        #
        class UnnecessaryMixlibShelloutRequire < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'Chef Infra Client 12.4+ includes mixlib/shellout automatically in resources and providers.'
          RESTRICT_ON_SEND = [:require].freeze

          def_node_matcher :require_mixlibshellout?, <<-PATTERN
          (send nil? :require ( str "mixlib/shellout"))
          PATTERN

          def on_send(node)
            require_mixlibshellout?(node) do
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
