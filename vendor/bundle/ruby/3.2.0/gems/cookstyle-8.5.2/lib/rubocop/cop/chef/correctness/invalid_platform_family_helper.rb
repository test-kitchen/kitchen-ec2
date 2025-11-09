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
        # Pass valid platform families to the `platform_family?` helper. See [Infra Language: Platform Family](https://docs.chef.io/infra_language/checking_platforms/#platform_family-values) for a complete list of platform families.
        #
        # @example
        #
        #   ### incorrect
        #   platform_family?('redhat')
        #   platform_family?('sles')
        #
        #   ### incorrect
        #   platform_family?('rhel')
        #   platform_family?('suse')
        #
        class InvalidPlatformFamilyHelper < Base
          include ::RuboCop::Chef::PlatformHelpers
          include RangeHelp
          extend AutoCorrector

          MSG = 'Pass valid platform families to the platform_family? helper.'
          RESTRICT_ON_SEND = [:platform_family?].freeze

          def_node_matcher :platform_family_helper?, <<-PATTERN
            (send nil? :platform_family? $str*)
          PATTERN

          def on_send(node)
            platform_family_helper?(node) do |plats|
              plats.to_a.each do |p|
                next unless INVALID_PLATFORM_FAMILIES.key?(p.value)
                add_offense(p, severity: :refactor) do |corrector|
                  replacement_platform = INVALID_PLATFORM_FAMILIES[p.value]
                  all_passed_platforms = p.parent.arguments.map(&:value)

                  # see if we have a replacement platform in our hash. If not we can't autocorrect
                  next unless replacement_platform
                  # if the replacement platform was one of the other platforms passed we can just delete this bad platform
                  if all_passed_platforms.include?(replacement_platform)
                    all_passed_platforms.delete(p.value)
                    arg_range = p.parent.arguments.first.loc.expression.join(p.parent.arguments.last.loc.expression.end)
                    corrector.replace(arg_range, all_passed_platforms.map { |x| "'#{x}'" }.join(', '))
                  else
                    corrector.replace(p.loc.expression, p.value.gsub(p.value, "'#{replacement_platform}'")) # gsub to retain quotes
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
