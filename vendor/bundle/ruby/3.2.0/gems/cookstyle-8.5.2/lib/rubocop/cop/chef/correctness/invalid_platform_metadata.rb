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
        # metadata.rb `supports` methods should contain valid platforms. See [Infra Language: Platform](https://docs.chef.io/infra_language/checking_platforms/#platform-values) for a list of many common platform values.
        #
        # @example
        #
        #   ### incorrect
        #   supports 'darwin'
        #   supports 'mswin'
        #
        #   ### correct
        #   supports 'mac_os_x'
        #   supports 'windows'
        #
        class InvalidPlatformMetadata < Base
          extend AutoCorrector
          include ::RuboCop::Chef::PlatformHelpers

          MSG = 'metadata.rb "supports" platform is invalid'
          RESTRICT_ON_SEND = [:supports].freeze

          def_node_matcher :supports?, '(send nil? :supports $str ...)'

          def_node_matcher :supports_array?, <<-PATTERN
            (block
              (send
                $(array ...) :each)
              (args
                (arg _))
              (send nil? :supports (lvar _)))
          PATTERN

          def on_send(node)
            supports?(node) do |plat|
              next unless INVALID_PLATFORMS[plat.str_content]
              add_offense(plat, severity: :refactor) do |corrector|
                correct_string = corrected_platform_source(plat)
                next unless correct_string
                corrector.replace(plat, correct_string)
              end
            end
          end

          def on_block(node)
            supports_array?(node) do |plats|
              plats.each_value do |plat|
                next unless INVALID_PLATFORMS[plat.str_content]
                add_offense(plat, severity: :refactor) do |corrector|
                  correct_string = corrected_platform_source(plat)
                  next unless correct_string
                  corrector.replace(plat, correct_string)
                end
              end
            end
          end

          # private

          def corrected_platform_source(node)
            val = INVALID_PLATFORMS[node.str_content.delete(',').downcase]
            return false unless val

            # if the value was previously quoted make sure to quote it again
            node.source.match?(/^('|")/) ? "'" + val + "'" : val
          end
        end
      end
    end
  end
end
