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
      module Sharing
        # metadata.rb should not include fields with an empty string. Either don't include the field or add a value.
        #
        # @example
        #
        #   ### incorrect
        #   license ''
        #
        #   ### correct
        #   license 'Apache-2.0'
        #
        class EmptyMetadataField < Base
          MSG = 'Cookbook metadata.rb contains a field with an empty string.'

          def_node_matcher :field?, '(send nil? _ $str ...)'

          def on_send(node)
            field?(node) do |str|
              return unless str.value.empty?
              add_offense(str, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
