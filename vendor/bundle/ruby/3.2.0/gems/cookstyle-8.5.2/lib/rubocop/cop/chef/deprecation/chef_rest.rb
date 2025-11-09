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
        # The `Chef::REST` class was removed in Chef Infra Client 13.
        #
        # @example
        #
        #   ### incorrect
        #   require 'chef/rest'
        #   Chef::REST::RESTRequest.new(:GET, FOO, nil).call
        #
        class UsesChefRESTHelpers < Base
          MSG = "Don't use the helpers in Chef::REST which were removed in Chef Infra Client 13"
          RESTRICT_ON_SEND = [:require].freeze

          def_node_matcher :require_rest?, <<-PATTERN
          (send nil? :require ( str "chef/rest"))
          PATTERN

          def_node_matcher :rest_const?, <<-PATTERN
          (const (const nil? :Chef) :REST)
          PATTERN

          def on_send(node)
            require_rest?(node) do
              add_offense(node, severity: :warning)
            end
          end

          def on_const(node)
            rest_const?(node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
