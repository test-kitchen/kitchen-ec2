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
      module Effortless
        # Policyfiles (and Effortless) do not use environments or roles so searching for those will need to be refactored before migrating to Policyfiles and the Effortless pattern.
        #
        # @example
        #
        #   ### incorrect
        #   search(:node, 'chef_environment:foo')
        #   search(:node, 'role:bar')
        #
        class SearchForEnvironmentsOrRoles < Base
          MSG = 'Cookbook uses search with a node query that looks for a role or environment'
          RESTRICT_ON_SEND = [:search].freeze

          def on_send(node)
            if node.arguments[1]&.value&.match?(/chef_environment|role/)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
