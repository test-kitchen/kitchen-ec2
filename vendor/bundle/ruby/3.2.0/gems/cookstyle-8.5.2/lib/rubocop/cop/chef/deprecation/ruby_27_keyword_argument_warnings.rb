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
      module Deprecations
        # Pass options to shell_out helpers without the brackets to avoid Ruby 2.7 deprecation warnings.
        #
        # @example
        #
        #   ### incorrect
        #   shell_out!('hostnamectl status', { returns: [0, 1] })
        #   shell_out('hostnamectl status', { returns: [0, 1] })
        #
        #   ### correct
        #   shell_out!('hostnamectl status', returns: [0, 1])
        #   shell_out('hostnamectl status', returns: [0, 1])
        #
        class Ruby27KeywordArgumentWarnings < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Pass options to shell_out helpers without the brackets to avoid Ruby 2.7 deprecation warnings.'
          RESTRICT_ON_SEND = [:shell_out!, :shell_out].freeze

          def_node_matcher :positional_shellout?, <<-PATTERN
            (send nil? {:shell_out :shell_out!} ... $(hash ... ))
          PATTERN

          def on_send(node)
            positional_shellout?(node) do |h|
              next unless h.braces?
              add_offense(h, severity: :refactor) do |corrector|
                corrector.replace(h, h.source[1..-2])
              end
            end
          end
        end
      end
    end
  end
end
