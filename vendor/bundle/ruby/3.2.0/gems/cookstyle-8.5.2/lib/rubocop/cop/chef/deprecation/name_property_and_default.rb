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
      module Deprecations
        # A resource property (or attribute) can't be marked as a name_property (or name_attribute) and also have a default value. The name property is a special property that is derived from the name of the resource block in and thus always has a value passed to the resource. For example if you define `my_resource 'foo'` in recipe, then the name property of `my_resource` will automatically be set to `foo`. Setting a property to be both a name_property and have a default value will cause Chef Infra Client failures in 13.0 and later releases.
        #
        # @example
        #
        #   ### incorrect
        #   property :config_file, String, default: 'foo', name_property: true
        #   attribute :config_file, String, default: 'foo', name_attribute: true
        #
        #   ### correct
        #   property :config_file, String, name_property: true
        #   attribute :config_file, String, name_attribute: true
        #
        class NamePropertyWithDefaultValue < Base
          include RangeHelp
          extend AutoCorrector

          MSG = "A resource property can't be marked as a name_property and also have a default value. This will fail in Chef Infra Client 13 or later."
          RESTRICT_ON_SEND = [:attribute, :property].freeze

          # match on a property or attribute that has any name and any type and a hash that
          # contains name_property/name_attribute true and any default value. These are wrapped in
          # <> which means the order doesn't matter in the hash.
          def_node_matcher :name_property_with_default?, <<-PATTERN
            (send nil? {:property :attribute} (sym _) ... (hash <(pair (sym {:name_property :name_attribute}) (true)) $(pair (sym :default) ...) ...>))
          PATTERN

          def on_send(node)
            name_property_with_default?(node) do |default|
              add_offense(node, severity: :warning) do |corrector|
                range = range_with_surrounding_comma(range_with_surrounding_space(range: default.loc.expression, side: :left), :left)
                corrector.remove(range)
              end
            end
          end
        end
      end
    end
  end
end
