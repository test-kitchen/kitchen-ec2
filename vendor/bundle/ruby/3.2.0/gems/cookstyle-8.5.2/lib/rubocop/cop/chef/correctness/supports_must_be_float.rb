# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # Versions used in metadata.rb supports calls should be floats not integers.
        #
        # @example
        #
        #   ### incorrect
        #   supports 'redhat', '> 8'
        #
        #   ### correct
        #   supports 'redhat', '> 8.0'
        #
        class SupportsMustBeFloat < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Versions used in metadata.rb supports calls should be floats not integers.'
          RESTRICT_ON_SEND = [:supports].freeze

          def_node_matcher :supports_with_constraint?, '(send nil? :supports str $str)'

          def on_send(node)
            supports_with_constraint?(node) do |ver|
              return if ver.source.include?('.')
              add_offense(ver, severity: :refactor) do |corrector|
                corrector.replace(ver, ver.source.gsub(ver.value, ver.value + '.0'))
              end
            end
          end
        end
      end
    end
  end
end
