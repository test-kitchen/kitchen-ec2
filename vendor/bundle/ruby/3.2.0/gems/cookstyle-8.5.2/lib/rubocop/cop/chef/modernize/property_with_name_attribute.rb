# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
        # When using properties in a custom resource you should use name_property not the legacy name_attribute from the days of attributes
        #
        # @example
        #
        #   ### incorrect
        #   property :bob, String, name_attribute: true
        #
        #   ### correct
        #   property :bob, String, name_property: true
        #
        class PropertyWithNameAttribute < Base
          extend AutoCorrector

          MSG = 'Resource property sets name_attribute instead of name_property'
          RESTRICT_ON_SEND = [:property].freeze

          # match on a property that has any name and any type and a hash that
          # contains name_attribute true. The hash pairs are wrapped in
          # <> which means the order doesn't matter in the hash.
          def_node_matcher :property_with_name_attribute?, <<-PATTERN
            (send nil? :property (sym _) ... (hash <$(pair (sym :name_attribute) (true)) ...>))
          PATTERN

          def on_send(node)
            property_with_name_attribute?(node) do |name_attribute|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(name_attribute, 'name_property: true')
              end
            end
          end
        end
      end
    end
  end
end
