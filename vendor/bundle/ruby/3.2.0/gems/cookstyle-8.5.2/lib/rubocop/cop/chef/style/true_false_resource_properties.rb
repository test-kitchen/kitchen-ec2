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
      module Style
        # When setting the allowed types for a resource to accept either true or false values it's much simpler to use true and false instead of TrueClass and FalseClass.
        #
        # @example
        #
        #   ### incorrect
        #   property :foo, [TrueClass, FalseClass]
        #
        #   ### correct
        #   property :foo, [true, false]
        #
        class TrueClassFalseClassResourceProperties < Base
          extend AutoCorrector

          MSG = "When setting the allowed types for a resource to accept either true or false values it's much simpler to use true and false instead of TrueClass and FalseClass."
          RESTRICT_ON_SEND = [:property, :attribute].freeze

          def_node_matcher :trueclass_falseclass_property?, <<-PATTERN
            (send nil? {:property :attribute} (sym _) $(array (const nil? :TrueClass) (const nil? :FalseClass)) ... )
          PATTERN

          def on_send(node)
            trueclass_falseclass_property?(node) do |types|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(types, '[true, false]')
              end
            end
          end
        end
      end
    end
  end
end
