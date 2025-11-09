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
      module Deprecations
        # The beta Audit Mode for Chef Infra Client was removed in Chef Infra Client 15.0. Users should instead use InSpec and the audit cookbook or the Compliance Phase introduced in Chef Infra Client 17. See https://www.inspec.io/ for more information.
        #
        # @example
        #
        #   ### incorrect
        #   control_group 'Baseline' do
        #     control 'SSH' do
        #       it 'should be listening on port 22' do
        #         expect(port(22)).to be_listening
        #       end
        #     end
        #   end
        class EOLAuditModeUsage < Base
          MSG = 'The beta Audit Mode feature in Chef Infra Client was removed in Chef Infra Client 15.0.'
          RESTRICT_ON_SEND = [:control_group].freeze

          def_node_matcher :control_group?, '(send nil? :control_group ...)'

          def on_send(node)
            control_group?(node) do
              add_offense(node.loc.selector, severity: :warning)
            end
          end
        end
      end
    end
  end
end
