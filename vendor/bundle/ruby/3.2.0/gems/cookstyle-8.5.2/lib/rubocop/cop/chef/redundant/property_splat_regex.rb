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
      module RedundantCode
        # When a property has a type of String it can accept any string. There is no need to also validate string inputs against a regex that accept all values.
        #
        # @example
        #
        #   ### incorrect
        #   property :config_file, String, regex: /.*/
        #   attribute :config_file, String, regex: /.*/
        #
        #   ### correct
        #   property :config_file, String
        #   attribute :config_file, String
        #
        class PropertySplatRegex < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'There is no need to validate the input of properties in resources using a regex value that will always pass.'
          RESTRICT_ON_SEND = [:property, :attribute].freeze

          def_node_matcher :property_with_regex_splat?, <<-PATTERN
            (send nil? {:property :attribute} (sym _) ... (hash <$(pair (sym :regex) (regexp (str ".*") (regopt))) ...>))
          PATTERN

          def on_send(node)
            property_with_regex_splat?(node) do |splat|
              add_offense(splat, severity: :refactor) do |corrector|
                range = range_with_surrounding_comma(
                  range_with_surrounding_space(
                    range: splat.loc.expression, side: :left), :left)
                corrector.remove(range)
              end
            end
          end
        end
      end
    end
  end
end
