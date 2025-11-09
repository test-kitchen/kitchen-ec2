# frozen_string_literal: true
#
# Copyright:: 2016-2019, Chef Software, Inc.
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
      module Style
        # Replaces double spaces between sentences with a single space.
        # Note: This is DISABLED by default.
        class CommentSentenceSpacing < Base
          extend AutoCorrector
          MSG = 'Use a single space after sentences in comments'

          def on_new_investigation
            return unless processed_source.ast

            processed_source.comments.each do |comment|
              next unless comment.text.match?(/(.|\?)\s{2}/) # https://rubular.com/r/8o3SiDrQMJSzuU
              add_offense(comment, severity: :refactor) do |corrector|
                corrector.replace(comment, comment.text.gsub('.  ', '. ').gsub('?  ', '? '))
              end
            end
          end
        end
      end
    end
  end
end
