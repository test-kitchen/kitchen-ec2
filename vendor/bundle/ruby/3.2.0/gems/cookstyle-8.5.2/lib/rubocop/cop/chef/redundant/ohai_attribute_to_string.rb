# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
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
        # Many Ohai node attributes are already strings and don't need to be cast to strings again
        #
        # @example
        #
        #   ### incorrect
        #   node['platform'].to_s
        #   node['platform_family'].to_s
        #   node['platform_version'].to_s
        #   node['fqdn'].to_s
        #   node['hostname'].to_s
        #   node['os'].to_s
        #   node['name'].to_s
        #
        #   ### correct
        #   node['platform']
        #   node['platform_family']
        #   node['platform_version']
        #   node['fqdn']
        #   node['hostname']
        #   node['os']
        #   node['name']
        #
        class OhaiAttributeToString < Base
          extend AutoCorrector

          MSG = "This Ohai node attribute is already a string and doesn't need to be converted"
          RESTRICT_ON_SEND = [:to_s].freeze

          def_node_matcher :attribute_to_s?, <<-PATTERN
            (send (send (send nil? :node) :[] $(str {"platform" "platform_family" "platform_version" "fqdn" "hostname" "os" "name"}) ) :to_s )
          PATTERN

          def on_send(node)
            attribute_to_s?(node) do |method|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "node['#{method.value}']")
              end
            end
          end
        end
      end
    end
  end
end
