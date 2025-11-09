# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
      module Sharing
        # Resource properties should include description fields to allow automated documentation. Requires Chef Infra Client 13.9 or later.
        #
        # @example
        #
        #   ### incorrect
        #   property :foo, String
        #
        #   ### correct
        #   property :foo, String, description: "Set the important thing to..."
        #
        class IncludePropertyDescriptions < Base
          extend TargetChefVersion

          minimum_target_chef_version '13.9'

          MSG = 'Resource properties should include description fields to allow automated documentation. Requires Chef Infra Client 13.9 or later.'
          RESTRICT_ON_SEND = [:property].freeze

          # any method named property being called with a symbol argument and anything else
          def_node_matcher :property?, '(send nil? :property (sym _) ...)'

          # hash that contains description in any order (that's the <> bit)
          def_node_search :description_hash?, '(hash <(pair (sym :description) ...) ...>)'

          def on_send(node)
            property?(node) do
              add_offense(node, severity: :refactor) unless description_hash?(node)
            end
          end
        end
      end
    end
  end
end
