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
        # The resource name can now be specified using the `resource_name` helper instead of using the @resource_name variable in the resource provider initialize method. In general we recommend against writing HWRPs, but if HWRPs are necessary you should utilize as much of the resource DSL as possible.
        #
        # @example
        #
        #   ### incorrect
        #   def initialize(*args)
        #     super
        #     @resource_name = :foo
        #   end
        #
        #  ### correct
        #  resource_name :create

        class ResourceNameFromInitialize < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'The name of a resource can be set with the "resource_name" helper instead of using the initialize method.'

          def on_def(node)
            return unless node.method?(:initialize)
            return if node.body.nil? # nil body is an empty initialize method

            node.body.each_node do |x|
              next unless x.assignment? && !x.node_parts.empty? && x.node_parts.first == :@resource_name

              add_offense(x, severity: :refactor) do |corrector|
                # insert the new resource_name call above the initialize method
                initialize_node = initialize_method(processed_source.ast).first
                corrector.insert_before(initialize_node.source_range, "resource_name #{x.descendants.first.source}\n\n")
                # remove the variable from the initialize method
                corrector.remove(range_with_surrounding_space(range: x.loc.expression, side: :left))
              end
            end
          end

          def_node_search :initialize_method, '(def :initialize ... )'
        end
      end
    end
  end
end
