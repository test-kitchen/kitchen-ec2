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
        # In Chef Infra Client 13 and later you must set path env vars in execute resources using the `environment` property not the legacy `path` property.
        #
        # @example
        #
        #   ### incorrect
        #   execute 'some_cmd' do
        #     path '/foo/bar'
        #   end
        #
        #   ### correct
        #   execute 'some_cmd' do
        #     environment {path: '/foo/bar'}
        #   end
        #
        class ExecutePathProperty < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'In Chef Infra Client 13 and later you must set path env vars in execute resources using the `environment` property not the legacy `path` property.'

          def on_block(node)
            match_property_in_resource?(:execute, 'path', node) do |offense|
              add_offense(offense, severity: :warning) # @todo: we could probably autocorrect this with some work
            end
          end
        end
      end
    end
  end
end
