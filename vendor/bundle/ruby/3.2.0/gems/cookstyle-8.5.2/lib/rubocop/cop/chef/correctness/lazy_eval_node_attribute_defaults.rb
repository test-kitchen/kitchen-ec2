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
        # When setting a node attribute as the default value for a custom resource property, wrap the node attribute in `lazy {}` so that its value is available when the resource executes.
        #
        # @example
        #
        #   ### incorrect
        #   property :Something, String, default: node['hostname']
        #
        #   ### correct
        #   property :Something, String, default: lazy { node['hostname'] }
        #
        class LazyEvalNodeAttributeDefaults < Base
          extend AutoCorrector
          include RuboCop::Chef::CookbookHelpers

          MSG = 'When setting a node attribute as the default value for a custom resource property, wrap the node attribute in `lazy {}` so that its value is available when the resource executes.'

          def_node_matcher :non_lazy_node_attribute_default?, <<-PATTERN
            (send nil? :property (sym _) ... (hash <(pair (sym :default) $(send (send _ :node) :[] _) ) ...>))
          PATTERN

          def on_send(node)
            non_lazy_node_attribute_default?(node) do |default|
              add_offense(default, severity: :refactor) do |corrector|
                corrector.replace(default, "lazy { #{default.source} }")
              end
            end
          end
        end
      end
    end
  end
end
