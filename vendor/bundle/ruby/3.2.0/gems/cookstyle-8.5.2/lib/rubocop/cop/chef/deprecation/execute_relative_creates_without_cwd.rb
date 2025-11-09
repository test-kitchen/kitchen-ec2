# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # In Chef Infra Client 13 and later you must either specific an absolute path when using the `execute` resource's `creates` property or also use the `cwd` property.
        #
        # @example
        #
        #   ### incorrect
        #   execute 'some_cmd' do
        #     creates 'something'
        #   end
        #
        #   ### correct
        #   execute 'some_cmd' do
        #     creates '/tmp/something'
        #   end
        #
        #   execute 'some_cmd' do
        #     creates 'something'
        #     cwd '/tmp/'
        #   end
        #
        class ExecuteRelativeCreatesWithoutCwd < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = "In Chef Infra Client 13 and later you must either specific an absolute path when using the `execute` resource's `creates` property or also use the `cwd` property."

          def on_block(node)
            match_property_in_resource?(:execute, 'creates', node) do |offense|
              return unless offense.arguments.one? # we can only analyze simple string args
              return unless offense.arguments.first.str_type? # we can only analyze simple string args

              # skip any creates that are abs paths https://rubular.com/r/3TbDsgcAa1EaIF
              return if offense.arguments.first.value.match?(%r{^(/|[a-zA-Z]:)})

              # return if we have a cwd property
              match_property_in_resource?(:execute, 'cwd', node) do
                return
              end

              add_offense(offense, severity: :warning)
            end
          end
        end
      end
    end
  end
end
