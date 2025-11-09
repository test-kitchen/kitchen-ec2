# frozen_string_literal: true
#
# Copyright:: Chef Software, Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
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
      module Ruby
        # All gemspec files should define their license.
        #
        # @example
        #
        #   # good
        #   spec.license = "Apache-2.0"
        #
        class GemspecLicense < Base
          include RangeHelp

          MSG = 'All gemspec files should define their license.'

          def_node_search :license, <<~PATTERN
            (send _ {:license= :licenses=} _)
          PATTERN

          def_node_search :eval_method, <<~PATTERN
            (send nil? {:eval :instance_eval} ... )
          PATTERN

          def on_new_investigation
            # exit if we find a license statement or any eval since that usually happens
            # when we have a windows platform gem that evals the main gemspec
            return if license(processed_source.ast).first || eval_method(processed_source.ast).first

            range = source_range(processed_source.buffer, 1, 0)
            add_offense(range, message: MSG, severity: :warning)
          end
        end
      end
    end
  end
end
