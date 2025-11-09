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
      module Correctness
        # Use name properties instead of setting the name property in a resource. Setting the name property directly causes notification and reporting issues.
        #
        # @example
        #
        #   ### incorrect
        #   service 'foo' do
        #    name 'bar'
        #   end
        #
        #   ### correct
        #   service 'foo' do
        #    service_name 'bar'
        #   end
        #
        class ResourceSetsNameProperty < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Resource sets the name property in the resource instead of using a name_property.'

          def on_block(node)
            match_property_in_resource?(nil, 'name', node) do |name_node|
              add_offense(name_node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
