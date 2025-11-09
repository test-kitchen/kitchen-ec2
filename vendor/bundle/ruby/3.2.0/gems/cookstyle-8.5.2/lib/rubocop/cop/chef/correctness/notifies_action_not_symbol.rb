# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # When notifying or subscribing actions within a resource the action should always be a symbol. In Chef Infra Client releases before 14.0, this may result in double notification.
        #
        # @example
        #
        #   ### incorrect
        #   execute 'some command' do
        #     notifies 'restart', 'service[httpd]', 'delayed'
        #   end
        #
        #   execute 'some command' do
        #     subscribes 'restart', 'service[httpd]', 'delayed'
        #   end
        #
        #   ### correct
        #   execute 'some command' do
        #     notifies :restart, 'service[httpd]', 'delayed'
        #   end
        #
        #   execute 'some command' do
        #     subscribes :restart, 'service[httpd]', 'delayed'
        #   end
        #
        class NotifiesActionNotSymbol < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = 'Resource notification and subscription actions should be symbols not strings.'

          def on_block(node)
            match_property_in_resource?(nil, %w(notifies subscribes), node) do |notifies_property|
              return unless notifies_property.node_parts[2].str_type?

              add_offense(notifies_property, severity: :refactor) do |corrector|
                corrector.replace(notifies_property.first_argument,
                  ":#{notifies_property.node_parts[2].value}")
              end
            end
          end
        end
      end
    end
  end
end
