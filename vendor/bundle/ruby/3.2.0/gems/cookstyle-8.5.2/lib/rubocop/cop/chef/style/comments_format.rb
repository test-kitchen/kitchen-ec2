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
        # Checks for incorrectly formatted headers
        #
        # @example
        #
        #   ### incorrect
        #   Copyright 2013-2016 Chef Software, Inc.
        #   Recipe default.rb
        #   Attributes default.rb
        #   License Apache2
        #   Cookbook tomcat
        #   Cookbook Name:: Tomcat
        #   Attributes File:: default
        #
        #   ### correct
        #   Copyright:: 2013-2016 Chef Software, Inc.
        #   Recipe:: default.rb
        #   Attributes:: default.rb
        #   License:: Apache License, Version 2.0
        #   Cookbook:: Tomcat
        #
        class CommentFormat < Base
          extend AutoCorrector

          MSG = 'Properly format header comments'
          VERBOSE_COMMENT_REGEX = /^#\s*([A-Za-z]+)\s?(?:Name|File)?(?:::)?\s(.*)/.freeze
          CHEF_LIKE_COMMENT_REGEX = /^#\s*(Author|Cookbook|Library|Attribute|Copyright|Recipe|Resource|Definition|License)\s+/.freeze

          def on_new_investigation
            return unless processed_source.ast

            processed_source.comments.each do |comment|
              next if comment.loc.first_line > 10 # avoid false positives when we were checking further down the file
              next unless comment.inline? && CHEF_LIKE_COMMENT_REGEX.match?(comment.text) # headers aren't in blocks

              add_offense(comment, severity: :refactor) do |corrector|
                # Extract the type and the actual value. Strip out "Name" or "File"
                # 'Cookbook Name' should be 'Cookbook'. Also skip a :: if present
                # https://rubular.com/r/Do9fpLWXlCmvdJ
                match = VERBOSE_COMMENT_REGEX.match(comment.text)
                comment_type, value = match.captures
                correct_comment = "# #{comment_type}:: #{value}"
                corrector.replace(comment, correct_comment)
              end
            end
          end
        end
      end
    end
  end
end
