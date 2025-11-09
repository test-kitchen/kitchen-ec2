# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software Inc.
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
        # metadata.rb cookbook dependencies and version constraints should be comma separated.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'some_awesome_cookbook' '= 4.5.5'
        #   depends 'some_other_cool_cookbook' '< 8.0'
        #
        #   ### correct
        #   depends 'some_awesome_cookbook', '= 4.5.5'
        #   depends 'some_other_cool_cookbook', '< 8.0'
        #
        class MetadataMalformedDepends < Base
          extend RuboCop::Cop::AutoCorrector

          RESTRICT_ON_SEND = [:depends].freeze
          MSG = 'metadata.rb cookbook dependencies and version constraints should be comma separated'

          def_node_matcher :depends_without_comma?, <<-PATTERN
            (send nil? :depends
              (dstr
                $(str _ )
                $(str _ )))
          PATTERN

          def on_send(node)
            depends_without_comma?(node) do |cb, ver|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "depends '#{cb.value}', '#{ver.value}'")
              end
            end
          end
        end
      end
    end
  end
end
