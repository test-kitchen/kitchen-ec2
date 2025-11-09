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
        # Chef InSpec attributes have been renamed to inputs. Use the `input` method not the deprecation `attribute` method to access these values.
        #
        # @example
        #
        #   ### incorrect
        #   login_defs_umask = attribute('login_defs_umask', value: '077', description: 'Default umask to set in login.defs')
        #
        #   ### correct
        #   login_defs_umask = input('login_defs_umask', value: '077', description: 'Default umask to set in login.defs')
        #
        class AttributeHelper < Base
          extend AutoCorrector

          MSG = 'InSpec attributes have been renamed to inputs. Use the `input` method not the deprecation `attribute` method to access these values.'
          RESTRICT_ON_SEND = [:attribute].freeze

          def on_send(node)
            add_offense(node, severity: :warning) do |corrector|
              corrector.replace(node.loc.expression, node.loc.expression.source.gsub(/^attribute/, 'input'))
            end
          end
        end
      end
    end
  end
end
