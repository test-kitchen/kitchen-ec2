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
        # Chef Infra Client 15.5 and later include a chef_sleep resource that should be used to sleep between executing resources if necessary instead of using the bash or execute resources to run the sleep command.
        #
        # @example
        #
        #   ### incorrect
        #   execute "sleep 60" do
        #     command "sleep 60"
        #     action :run
        #   end
        #
        #   bash 'sleep' do
        #     user 'root'
        #     cwd '/tmp'
        #     code 'sleep 60'
        #   end
        #
        #   ### correct
        #   chef_sleep '60'
        #
        class ExecuteSleep < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '15.5'

          MSG = 'Chef Infra Client 15.5 and later include a chef_sleep resource that should be used to sleep between executing resources if necessary instead of using the bash or execute resources to run the sleep command.'
          RESTRICT_ON_SEND = [:execute].freeze

          # non block execute resources
          def on_send(node)
            # use a regex on source instead of .value in case there's string interpolation which adds a complex dstr type
            # with a nested string and a begin. Source allows us to avoid a lot of defensive programming here
            return unless node&.arguments.first&.source&.match?(/^("|')sleep/)
            add_offense(node, severity: :refactor)
          end

          # block execute resources
          def on_block(node)
            match_property_in_resource?(:execute, 'command', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              next unless property_data && property_data.match?(/^sleep/i)
              add_offense(node, severity: :refactor)
            end

            match_property_in_resource?(:bash, 'code', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              next unless property_data && property_data.match?(/^sleep/i)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
