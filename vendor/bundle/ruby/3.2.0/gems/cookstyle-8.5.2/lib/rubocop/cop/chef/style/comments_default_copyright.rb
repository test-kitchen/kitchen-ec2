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
        # Checks for default copyright comments from the chef generator cookbook command
        #
        # @example
        #
        #   ### incorrect
        #   Copyright:: 2019 YOUR_NAME
        #   Copyright:: 2019 YOUR_COMPANY_NAME
        #
        #   ### correct
        #   Copyright:: 2019 Tim Smith
        #   Copyright:: 2019 Chef Software, Inc.
        #
        class DefaultCopyrightComments < Base
          MSG = 'Cookbook copyright comment headers should be updated for a real person or organization.'

          def on_new_investigation
            return unless processed_source.ast

            processed_source.comments.each do |comment|
              next unless comment.inline? && # headers aren't in blocks
                          /# (?:Copyright\W*).*YOUR_(NAME|COMPANY_NAME)/.match?(comment.text)
              add_offense(comment, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
