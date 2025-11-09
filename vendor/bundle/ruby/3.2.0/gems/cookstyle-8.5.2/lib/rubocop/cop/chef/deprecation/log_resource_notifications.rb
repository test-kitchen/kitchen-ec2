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
        # In Chef Infra Client 16 the log resource no longer notifies when logging so notifications should not be triggered from log resources. Use the notify_group resource introduced in Chef Infra Client 15.8 instead to aggregate notifications.
        #
        # @example
        #
        #   ### incorrect
        #   template '/etc/foo' do
        #     source 'bar.erb'
        #     notifies :write, 'log[Aggregate notifications using a single log resource]', :immediately
        #   end
        #
        #   log 'Aggregate notifications using a single log resource' do
        #     notifies :restart, 'service[foo]', :delayed
        #   end
        #
        #   ### correct
        #   template '/etc/foo' do
        #     source 'bar.erb'
        #     notifies :run, 'notify_group[Aggregate notifications using a single notify_group resource]', :immediately
        #   end
        #
        #   notify_group 'Aggregate notifications using a single notify_group resource' do
        #     notifies :restart, 'service[foo]', :delayed
        #   end
        #
        class LogResourceNotifications < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '15.8'

          MSG = 'In Chef Infra Client 16 the log resource no longer notifies when logging so notifications should not be triggered from log resources. Use the notify_group resource introduced in Chef Infra Client 15.8 instead to aggregate notifications.'

          def on_block(node)
            match_property_in_resource?(:log, 'notifies', node) do |prop_node|
              add_offense(prop_node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
