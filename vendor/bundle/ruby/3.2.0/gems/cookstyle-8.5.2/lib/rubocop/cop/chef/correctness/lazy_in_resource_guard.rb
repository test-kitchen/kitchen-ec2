# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
        # Using `lazy {}` within a resource guard (not_if/only_if) will cause failures and is unnecessary as resource guards are always lazily evaluated.
        #
        # @example
        #
        #   ### incorrect
        #   template '/etc/foo' do
        #     mode '0644'
        #     source 'foo.erb'
        #     only_if { lazy { ::File.exist?('/etc/foo')} }
        #   end
        #
        #   ### correct
        #   template '/etc/foo' do
        #     mode '0644'
        #     source 'foo.erb'
        #     only_if { ::File.exist?('/etc/foo') }
        #   end
        #
        class LazyInResourceGuard < Base
          extend AutoCorrector

          MSG = 'Using `lazy {}` within a resource guard (not_if/only_if) will cause failures and is unnecessary as resource guards are always lazily evaluated.'

          def_node_matcher :lazy_in_guard?, <<-PATTERN
            (block
              (send nil? ${:not_if :only_if})
              (args)
              (block
                (send nil? :lazy)
                (args)
                $(...)
             ))
          PATTERN

          def on_block(node)
            lazy_in_guard?(node) do |type, code|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "#{type} { #{code.source} }")
              end
            end
          end
        end
      end
    end
  end
end
