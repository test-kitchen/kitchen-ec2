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
      module Modernize
        # Remove legacy code comments that disable Foodcritic rules. These comments are no longer necessary if you've migrated from Foodcritic to Cookstyle for cookbook linting.
        #
        # @example
        #
        #   ### incorrect
        #   # ~FC013
        #
        class FoodcriticComments < Base
          extend AutoCorrector

          MSG = 'Remove legacy code comments that disable Foodcritic rules'

          def on_new_investigation
            processed_source.comments.each do |comment|
              next unless comment.text.match?(/#\s*~FC\d{3}.*/)
              add_offense(comment, severity: :refactor) do |corrector|
                corrector.remove(comment)
              end
            end
          end
        end
      end
    end
  end
end
