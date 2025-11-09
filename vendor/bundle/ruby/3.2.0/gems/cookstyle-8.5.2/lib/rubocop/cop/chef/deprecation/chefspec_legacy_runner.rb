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
      module Deprecations
        # Use `ChefSpec::SoloRunner` or `ChefSpec::ServerRunner` instead of the deprecated `ChefSpec::Runner`. These new runners were introduced in ChefSpec 4.1 (Oct 2014).
        #
        # @example
        #
        #   ### incorrect
        #
        #   describe 'foo::default' do
        #     subject { ChefSpec::Runner.new.converge(described_recipe) }
        #
        #     # some spec code
        #   end
        #
        #   ### correct
        #
        #   describe 'foo::default' do
        #     subject { ChefSpec::ServerRunner.new.converge(described_recipe) }
        #
        #     # some spec code
        #   end
        #
        class ChefSpecLegacyRunner < Base
          extend AutoCorrector
          MSG = 'Use ChefSpec::SoloRunner or ChefSpec::ServerRunner instead of the deprecated ChefSpec::Runner.'

          def_node_matcher :chefspec_runner?, <<-PATTERN
          (const (const nil? :ChefSpec) :Runner)
          PATTERN

          def on_const(node)
            chefspec_runner?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.replace(node, 'ChefSpec::ServerRunner')
              end
            end
          end
        end
      end
    end
  end
end
