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
        # When using the value_for_platform helper you must include a hash of possible platforms where each platform contains a hash of versions and potential values. If you don't wish to match on a particular version you can instead use the key 'default'.
        #
        # @example
        #
        #   ### incorrect
        #   value_for_platform(
        #     %w(redhat oracle) => 'baz'
        #   )
        #
        #   ### correct
        #   value_for_platform(
        #     %w(redhat oracle) => {
        #       '5' => 'foo',
        #       '6' => 'bar',
        #       'default'd => 'baz',
        #     }
        #   )
        #
        #   value_for_platform(
        #     %w(redhat oracle) => {
        #       'default' => 'foo',
        #     },
        #     'default' => 'bar'
        #   )
        #
        class MalformedPlatformValueForPlatformHelper < Base
          RESTRICT_ON_SEND = [:value_for_platform].freeze

          def on_send(node)
            if node.arguments.count > 1
              msg = 'Malformed value_for_platform helper argument. The value_for_platform helper takes a single hash of platforms as an argument.'
              add_offense(node, message: msg, severity: :refactor)
            elsif node.arguments.first.hash_type? # if it's a variable we can't check what's in that variable so skip
              msg = "Malformed value_for_platform helper argument. The value for each platform in your hash must be a hash of either platform version strings or a value with a key of 'default'"
              node.arguments.first.each_pair do |plats, plat_vals|
                # instead of a platform the hash key can be default with a value of anything. Depending on the hash format this is a string or symbol
                next if plat_vals.hash_type? || plats == s(:str, 'default') || plats == s(:sym, :default)
                add_offense(plat_vals, message: msg, severity: :refactor)
              end
            end
          end
        end
      end
    end
  end
end
