# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software Inc.
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
      module RedundantCode
        # The grouping metadata.rb method is not used and is unnecessary in cookbooks.
        #
        # @example
        #
        #   ### incorrect
        #   grouping 'windows_log_rotate', title: 'Demonstration cookbook with code to switch loggers'
        #
        class GroupingMetadata < Base
          include RangeHelp
          include RuboCop::Chef::AutocorrectHelpers
          extend AutoCorrector

          MSG = 'The grouping metadata.rb method is not used and is unnecessary in cookbooks.'
          RESTRICT_ON_SEND = [:grouping].freeze

          def on_send(node)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.remove(range_with_surrounding_space(range: expression_including_heredocs(node), side: :left))
            end
          end
        end
      end
    end
  end
end
