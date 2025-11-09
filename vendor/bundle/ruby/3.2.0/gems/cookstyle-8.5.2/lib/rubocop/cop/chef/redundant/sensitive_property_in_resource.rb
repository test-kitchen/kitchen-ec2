# frozen_string_literal: true
#
# Copyright:: Copyright 2019-2020, Chef Software Inc.
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
        # Every Chef Infra resource already includes a sensitive property with a default value of false.
        #
        # @example
        #
        # ### incorrect
        # property :sensitive, [true, false], default: false
        #
        class SensitivePropertyInResource < Base
          extend AutoCorrector

          MSG = 'Every Chef Infra resource already includes a sensitive property with a default value of false.'
          RESTRICT_ON_SEND = [:property, :attribute].freeze

          def_node_matcher :sensitive_property?, <<-PATTERN
            (send nil? {:property :attribute} (sym :sensitive) ... (hash (pair (sym :default) (false))))
          PATTERN

          def on_send(node)
            return unless sensitive_property?(node)

            add_offense(node, severity: :refactor) do |corrector|
              corrector.remove(node.source_range)
            end
          end
        end
      end
    end
  end
end
