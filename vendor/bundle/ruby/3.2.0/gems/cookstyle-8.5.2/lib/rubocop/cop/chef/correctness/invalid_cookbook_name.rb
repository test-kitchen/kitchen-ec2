# frozen_string_literal: true
#
# Copyright:: 2022, Chef Software Inc.
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
        # Cookbook names should not contain invalid characters such as periods.
        #
        # @example
        #
        #   ### incorrect
        #   name 'foo.bar'
        #
        #   ### correct
        #   name 'foo_bar'
        #
        class InvalidCookbookName < Base
          RESTRICT_ON_SEND = [:name].freeze
          MSG = 'Cookbook names should not contain invalid characters such as periods.'

          def_node_matcher :has_name?, '(send nil? :name $str)'

          def on_send(node)
            has_name?(node) do |val|
              add_offense(node, severity: :refactor) if val.value.include?('.')
            end
          end
        end
      end
    end
  end
end
