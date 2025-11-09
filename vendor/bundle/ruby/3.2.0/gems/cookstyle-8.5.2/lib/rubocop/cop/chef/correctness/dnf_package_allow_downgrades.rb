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
      module Correctness
        # The `dnf_package` resource does not support the `allow_downgrades` property.
        #
        # @example
        #
        #   ### incorrect
        #   dnf_package 'nginx' do
        #     version '1.2.3'
        #     allow_downgrades true
        #   end
        #
        #   ### correct
        #   dnf_package 'nginx' do
        #     version '1.2.3'
        #   end
        #
        class DnfPackageAllowDowngrades < Base
          include RangeHelp
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = 'dnf_package does not support the allow_downgrades property'

          def on_block(node)
            match_property_in_resource?(:dnf_package, :allow_downgrades, node) do |prop|
              add_offense(prop, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: prop.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
