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
        # Don't use node.save to save partial node data to the Chef Infra Server mid-run unless it's a requirement of cookbook design that can't be avoided. Node.save can result in failed Chef Infra runs appearing in search and increases load on the Chef Infra Server."
        #
        # @example
        #
        #   ### incorrect
        #   node.save
        #
        class CookbookUsesNodeSave < Base
          MSG = "Don't use node.save to save partial node data to the Chef Infra Server mid-run unless it's absolutely necessary. Node.save can result in failed Chef Infra runs appearing in search and increases load on the Chef Infra Server."
          RESTRICT_ON_SEND = [:save].freeze

          def_node_matcher :node_save?, <<-PATTERN
            (send (send nil? :node) :save)
          PATTERN

          def on_send(node)
            node_save?(node) do
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
