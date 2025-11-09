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
      module Correctness
        # Pass valid platform families to the value_for_platform_family helper. See [Infra Language: Platform Family](https://docs.chef.io/infra_language/checking_platforms/#platform_family-values) for a complete list of platform families.
        #
        # @example
        #
        #   ### incorrect
        #   value_for_platform_family(
        #     %w(rhel sles) => 'foo',
        #     %w(mac) => 'foo'
        #   )
        #
        #   ### correct
        #   value_for_platform_family(
        #     %w(rhel suse) => 'foo',
        #     %w(mac_os_x) => 'foo'
        #   )
        #
        class InvalidPlatformValueForPlatformFamilyHelper < Base
          include ::RuboCop::Chef::PlatformHelpers

          MSG = 'Pass valid platform families to the value_for_platform_family helper.'
          RESTRICT_ON_SEND = [:value_for_platform_family].freeze

          def_node_matcher :value_for_platform_family?, <<-PATTERN
          (send nil? :value_for_platform_family
            (hash
              $...
            )
          )
          PATTERN

          def on_send(node)
            value_for_platform_family?(node) do |plats|
              plats.each do |p_hash|
                if p_hash.key.array_type?
                  p_hash.key.each_value do |plat|
                    next unless INVALID_PLATFORM_FAMILIES.key?(plat.value)
                    add_offense(plat, severity: :refactor)
                  end
                elsif INVALID_PLATFORM_FAMILIES.key?(p_hash.key.value)
                  add_offense(p_hash.key, severity: :refactor)
                end
              end
            end
          end
        end
      end
    end
  end
end
