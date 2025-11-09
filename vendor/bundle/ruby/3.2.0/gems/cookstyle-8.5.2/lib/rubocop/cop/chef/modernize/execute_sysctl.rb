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
      module Modernize
        # Chef Infra Client 14.0 and later includes a sysctl resource that should be used to idempotently load sysctl values instead of templating files and using execute to load them.
        #
        # @example
        #
        #   ### incorrect
        #   file '/etc/sysctl.d/ipv4.conf' do
        #     notifies :run, 'execute[sysctl -p /etc/sysctl.d/ipv4.conf]', :immediately
        #     content '9000 65500'
        #   end
        #
        #   execute 'sysctl -p /etc/sysctl.d/ipv4.conf' do
        #     action :nothing
        #   end
        #
        #   ### correct
        #   sysctl 'net.ipv4.ip_local_port_range' do
        #     value '9000 65500'
        #   end
        #
        class ExecuteSysctl < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '14.0'

          MSG = 'Chef Infra Client 14.0 and later includes a sysctl resource that should be used to idempotently load sysctl values instead of templating files and using execute to load them.'
          RESTRICT_ON_SEND = [:execute].freeze

          # non block execute resources
          def on_send(node)
            # use a regex on source instead of .value in case there's string interpolation which adds a complex dstr type
            # with a nested string and a begin. Source allows us to avoid a lot of defensive programming here
            return unless node&.arguments.first&.source&.match?(/^("|')sysctl -p/)
            add_offense(node, severity: :refactor)
          end

          # block execute resources
          def on_block(node)
            match_property_in_resource?(:execute, 'command', node) do |code_property|
              property_data = method_arg_ast_to_string(code_property)
              return unless property_data && property_data.match?(%r{^(/sbin/)?sysctl -p}i)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
