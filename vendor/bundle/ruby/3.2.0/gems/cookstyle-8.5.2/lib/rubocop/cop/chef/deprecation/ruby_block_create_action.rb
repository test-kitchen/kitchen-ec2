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
        # Use the :run action in the ruby_block resource instead of the deprecated :create action
        #
        # @example
        #
        #   ### incorrect
        #   ruby_block 'my special ruby block' do
        #     block do
        #       puts 'running'
        #     end
        #     action :create
        #   end
        #
        #   ### correct
        #   ruby_block 'my special ruby block' do
        #     block do
        #       puts 'running'
        #     end
        #     action :run
        #   end
        #
        class RubyBlockCreateAction < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector

          MSG = 'Use the :run action in the ruby_block resource instead of the deprecated :create action'

          def on_block(node)
            match_property_in_resource?(:ruby_block, 'action', node) do |ruby_action|
              ruby_action.arguments.each do |action|
                next unless action.source == ':create'
                add_offense(action, severity: :warning) do |corrector|
                  corrector.replace(action, ':run')
                end
              end
            end
          end
        end
      end
    end
  end
end
