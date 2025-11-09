# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software Inc.
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
    module InSpec
      module Deprecations
        # The Chef InSpec inputs `default` option has been replaced with the `value` option.
        #
        # @example
        #
        #   ### incorrect
        #   login_defs_umask = input('login_defs_umask', default: '077', description: 'Default umask to set in login.defs')
        #
        #   ### correct
        #   login_defs_umask = input('login_defs_umask', value: '077', description: 'Default umask to set in login.defs')
        #
        class AttributeDefault < Base
          extend AutoCorrector

          MSG = 'The InSpec inputs `default` option has been replaced with the `value` option.'
          RESTRICT_ON_SEND = [:attribute, :input].freeze

          def_node_matcher :default?, <<-PATTERN
            (send nil? {:attribute :input} _ (hash <(pair $(sym :default) ...) ...>) )
          PATTERN

          def on_send(node)
            default?(node) do |n|
              add_offense(n, severity: :warning) do |corrector|
                corrector.replace(n, 'value')
              end
            end
          end
        end
      end
    end
  end
end
