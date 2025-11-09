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
        # A resource guard (not_if/only_if) that is a string should not be wrapped in `{}`. Wrapping a guard string in {} causes it to be executed as Ruby code which will always return true instead of a shell command that will actually run.
        #
        # @example
        #
        #   ### incorrect
        #   template '/etc/foo' do
        #     mode '0644'
        #     source 'foo.erb'
        #     only_if { 'test -f /etc/foo' }
        #   end
        #
        #   ### correct
        #   template '/etc/foo' do
        #     mode '0644'
        #     source 'foo.erb'
        #     only_if 'test -f /etc/foo'
        #   end
        #
        class BlockGuardWithOnlyString < Base
          extend AutoCorrector

          MSG = 'A resource guard (not_if/only_if) that is a string should not be wrapped in {}. Wrapping a guard string in {} causes it to be executed as Ruby code which will always return true instead of a shell command that will actually run.'

          def_node_matcher :block_guard_with_only_string?, <<-PATTERN
            (block (send nil? ${:not_if :only_if}) (args) (str $_) )
          PATTERN

          def on_block(node)
            block_guard_with_only_string?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                new_val = "#{node.method_name} #{node.body.source}"
                corrector.replace(node, new_val)
              end
            end
          end
        end
      end
    end
  end
end
