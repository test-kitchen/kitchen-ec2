# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software, Inc.
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
      module Modernize
        # if defined?(default_action) is no longer necessary in Chef Resources as default_action shipped in Chef 10.8.
        #
        # @example
        #
        #   ### incorrect
        #   default_action :foo if defined?(default_action)
        #
        #   ### correct
        #   default_action :foo
        #
        class IfProvidesDefaultAction < Base
          extend AutoCorrector

          MSG = 'if defined?(default_action) is no longer necessary in Chef Resources as default_action shipped in Chef 10.8.'

          def on_defined?(node)
            return unless node.arguments.first == s(:send, nil, :default_action)
            node = node.parent if node.parent.respond_to?(:if?) && node.parent.if? # we want the whole if statement
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.children[1].source)
            end
          end
        end
      end
    end
  end
end
