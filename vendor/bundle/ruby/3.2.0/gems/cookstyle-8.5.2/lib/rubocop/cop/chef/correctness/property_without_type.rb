# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
        # Resource properties or attributes should always define a type to help users understand the correct allowed values.
        #
        # @example
        #
        #   ### incorrect
        #   property :size, regex: /^\d+[KMGTP]$/
        #   attribute :size, regex: /^\d+[KMGTP]$/
        #
        #   ### correct
        #   property :size, String, regex: /^\d+[KMGTP]$/
        #   attribute :size, kind_of: String, regex: /^\d+[KMGTP]$/
        #
        class PropertyWithoutType < Base
          MSG = 'Resource properties or attributes should always define a type to help users understand the correct allowed values.'
          RESTRICT_ON_SEND = [:property, :attribute].freeze

          def_node_matcher :property_without_type?, <<-PATTERN
          (send nil? {:property :attribute}
            (sym _)
            $(hash

              ...
            )?
          )
          PATTERN

          def on_send(node)
            property_without_type?(node) do |hash_vals|
              return if hash_vals&.first&.keys&.include?(s(:sym, :kind_of))

              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
