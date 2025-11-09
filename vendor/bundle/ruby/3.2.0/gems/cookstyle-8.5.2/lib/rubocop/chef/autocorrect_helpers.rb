# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
  module Chef
    # Helpers for use in autocorrection
    module AutocorrectHelpers
      # if the node has a heredoc as an argument you'll only get the start of the heredoc and removing
      # the node will result in broken ruby. This way we match the node and the entire heredoc for removal
      def expression_including_heredocs(node)
        if node.arguments.last.respond_to?(:heredoc?) && node.arguments.last.heredoc?
          node.loc.expression.join(node.arguments.last.loc.heredoc_end)
        else
          node.loc.expression
        end
      end
    end
  end
end
