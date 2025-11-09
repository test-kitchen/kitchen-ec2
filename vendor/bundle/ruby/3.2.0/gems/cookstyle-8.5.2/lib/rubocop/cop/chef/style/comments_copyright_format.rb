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
        # Checks for incorrectly formatted copyright comments.
        #
        # @example
        #
        #   ### incorrect
        #   Copyright:: 2013-2022 Opscode, Inc.
        #   Copyright:: 2013-2022 Chef Inc.
        #   Copyright:: 2013-2022 Chef Software Inc.
        #   Copyright:: 2009-2010 2013-2022 Chef Software Inc.
        #   Copyright:: Chef Software Inc.
        #   Copyright:: Tim Smith
        #   Copyright:: Copyright (c) 2015-2022 Chef Software, Inc.
        #
        #   ### correct
        #   Copyright:: 2013-2022 Chef Software, Inc.
        #   Copyright:: 2013-2022 Tim Smith
        #   Copyright:: 2019 37Signals, Inc.
        #
        class CopyrightCommentFormat < Base
          extend AutoCorrector
          require 'date'

          MSG = 'Properly format copyrights header comments'

          def on_new_investigation
            return unless processed_source.ast

            processed_source.comments.each do |comment|
              next unless comment.inline? && invalid_copyright_comment?(comment) # headers aren't in blocks

              add_offense(comment, severity: :refactor) do |corrector|
                correct_comment = "# Copyright:: #{copyright_date_range(comment)}, #{copyright_holder(comment)}"
                corrector.replace(comment, correct_comment)
              end
            end
          end

          private

          def copyright_date_range(comment)
            dates = comment.text.scan(/([0-9]{4})/)

            # no copyright year present so return this year
            return Time.new.year if dates.empty?

            oldest_date = dates.min.first.to_i

            # Avoid returning THIS_YEAR - THIS_YEAR
            if oldest_date == Time.new.year
              oldest_date
            else
              "#{oldest_date}-#{Time.new.year}"
            end
          end

          def copyright_holder(comment)
            # Grab just the company / individual name w/o :: or dates
            match = /(?:.*[0-9]{4}|Copyright\W*)(?:,)?(?:\s)?(.*)/.match(comment.text)
            marketing_sanitizer(match.captures.first)
          end

          # Flush Opscode down the memory hole and Chef Inc is not a company
          def marketing_sanitizer(name)
            name.gsub('Opscode', 'Chef Software').gsub(/Chef(?:,)? Inc.*/, 'Chef Software, Inc.')
          end

          def invalid_copyright_comment?(comment)
            match = /# (?:Copyright\W*)(.*)/.match(comment.text)
            return false unless match # it's not even a copyright

            current_text = match.captures.first
            desired_text = "#{copyright_date_range(comment)}, #{copyright_holder(comment)}"

            true unless current_text == desired_text
          end
        end
      end
    end
  end
end
