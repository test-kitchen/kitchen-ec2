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
      module Correctness
        # Valid notification timings are `:immediately`, `:immediate` (alias for :immediately), `:delayed`, and `:before`.
        #
        # @example
        #
        #   ### incorrect
        #
        #   template '/etc/www/configures-apache.conf' do
        #     notifies :restart, 'service[apache]', :nope
        #   end
        #
        #   ### correct
        #
        #   template '/etc/www/configures-apache.conf' do
        #     notifies :restart, 'service[apache]', :immediately
        #   end
        #
        class InvalidNotificationTiming < Base
          MSG = 'Valid notification timings are :immediately, :immediate (alias for :immediately), :delayed, and :before.'
          RESTRICT_ON_SEND = [:notifies, :subscribes].freeze

          def_node_matcher :notification_with_timing?, <<-PATTERN
            (send nil? {:notifies :subscribes} (sym _) (...) $(sym _))
          PATTERN

          def on_send(node)
            notification_with_timing?(node) do |timing|
              add_offense(timing, severity: :refactor) unless %i(immediate immediately delayed before).include?(timing.value)
            end
          end
        end
      end
    end
  end
end
