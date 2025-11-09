# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
# Author:: Scott Vidmar (<svidmar@chef.io>)
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
        # Chef Vault is not supported in the Effortless pattern, so usage of Chef Vault must be shifted to another secrets management solution before leveraging the Effortless pattern.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'chef-vault'
        #
        class DependsChefVault < Base
          MSG = 'Chef Vault usage is not supported in the Effortless pattern'
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :depends?, <<-PATTERN
            (send nil? :depends
              (str "chef-vault"))
          PATTERN

          def on_send(node)
            depends?(node) do
              add_offense(node.loc.expression, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
