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
      module RedundantCode
        # If a resource includes the `compile_time` property there's no need to also use `.run_action(:some_action)` on the resource block
        #
        # @example
        #
        #   ### incorrect
        #   chef_gem 'deep_merge' do
        #     action :nothing
        #     compile_time true
        #   end.run_action(:install)
        #
        #   ### correct
        #   chef_gem 'deep_merge' do
        #     action :install
        #     compile_time true
        #   end
        #
        class DoubleCompileTime < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = "If a resource includes the `compile_time` property there's no need to also use `.run_action(:some_action)` on the resource block."
          RESTRICT_ON_SEND = [:run_action].freeze

          def_node_matcher :compile_time_and_run_action?, <<-PATTERN
          (send
            $(block
              (send nil? ... )
              (args)
              (begin <
                (send nil? :action (sym $_) )
                (send nil? :compile_time (true) )
                ...
              >)
            ) :run_action (sym $_) )
          PATTERN

          def on_send(node)
            compile_time_and_run_action?(node) do |resource, action, run_action|
              add_offense(node.loc.selector, severity: :refactor) do |corrector|
                corrector.replace(node, resource.source.gsub(action.to_s, run_action.to_s))
              end
            end
          end
        end
      end
    end
  end
end
