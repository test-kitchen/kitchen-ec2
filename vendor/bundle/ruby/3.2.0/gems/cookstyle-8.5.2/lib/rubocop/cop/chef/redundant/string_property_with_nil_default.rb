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
        # Properties have a nil value by default so there is no need to set the default value to nil.
        #
        # @example
        #
        #   ### incorrect
        #   property :config_file, String, default: nil
        #   property :config_file, [String, NilClass], default: nil
        #
        #   ### correct
        #   property :config_file, String
        #   property :config_file, [String, NilClass]
        #
        class StringPropertyWithNilDefault < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'Properties have a nil value by default so there is no need to set the default value to nil.'
          RESTRICT_ON_SEND = [:property].freeze

          def_node_matcher :string_property_with_nil_default?, <<-PATTERN
            (send nil? :property (sym _)
            {(const nil? :String) #string_and_nil_like?}
            (hash <$(pair (sym :default) (nil)) ...>))
          PATTERN

          # An array of types that includes String & either NilClass or nil
          def_node_matcher :string_and_nil_like?, <<-PATTERN
            (array <(const nil? :String) {(const nil? :NilClass) (nil)}>)
          PATTERN

          def on_send(node)
            string_property_with_nil_default?(node) do |nil_default|
              add_offense(nil_default, severity: :refactor) do |corrector|
                range = range_with_surrounding_comma(range_with_surrounding_space(range: nil_default.loc.expression, side: :left), :left)
                corrector.remove(range)
              end
            end
          end
        end
      end
    end
  end
end
