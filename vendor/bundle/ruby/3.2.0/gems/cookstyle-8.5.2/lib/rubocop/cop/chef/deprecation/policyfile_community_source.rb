# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software, Inc.
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
        # The Policyfile source of `:community` has been replaced with `:supermarket`
        #
        # @example
        #
        #   ### incorrect
        #   default_source :community
        #
        #   ### correct
        #   default_source :supermarket
        #
        class PolicyfileCommunitySource < Base
          extend AutoCorrector

          MSG = 'The Policyfile source of `:community` has been replaced with `:supermarket`.'
          RESTRICT_ON_SEND = [:default_source].freeze

          def_node_matcher :community_source?, <<-PATTERN
            (send nil? :default_source (:sym :community))
          PATTERN

          def on_send(node)
            community_source?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.replace(node, 'default_source :supermarket')
              end
            end
          end
        end
      end
    end
  end
end
