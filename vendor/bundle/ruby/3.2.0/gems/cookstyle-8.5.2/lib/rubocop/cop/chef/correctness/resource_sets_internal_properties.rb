# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
        # Chef Infra Client uses properties in several resources to track state. These should not be set in recipes as they break the internal workings of the Chef Infra Client
        #
        # @example
        #
        #   ### incorrect
        #   service 'foo' do
        #     running true
        #     action [:start, :enable]
        #   end
        #
        #   ### correct
        #   service 'foo' do
        #     action [:start, :enable]
        #   end
        #
        class ResourceSetsInternalProperties < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Do not set properties used internally by Chef Infra Client to track the system state.'

          def on_block(node)
            match_property_in_resource?(:service, 'running', node) do |prop|
              add_offense(prop, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
