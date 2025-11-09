# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
      module Correctness
        # Default actions in resources should be symbols or an array of symbols.
        #
        # @example
        #
        #   ### incorrect
        #   default_action 'create'
        #
        #   ### correct
        #   default_action :create
        #
        class InvalidDefaultAction < Base
          MSG = 'Default actions in resources should be symbols or an array of symbols.'
          RESTRICT_ON_SEND = [:default_action].freeze

          def_node_matcher :default_action?, '(send nil? :default_action $_)'

          def on_send(node)
            default_action?(node) do |match|
              return if %i(send sym array).include?(match.type)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
