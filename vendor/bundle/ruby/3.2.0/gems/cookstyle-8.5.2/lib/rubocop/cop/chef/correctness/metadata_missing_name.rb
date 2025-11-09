# frozen_string_literal: true
#
# Copyright:: 2019-2021, Chef Software Inc.
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
        # metadata.rb needs to include the name method or it will fail on Chef Infra Client 12 and later.
        #
        # @example
        #
        #   ### correct
        #   name 'foo'
        #
        class MetadataMissingName < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'metadata.rb needs to include the name method or it will fail on Chef Infra Client 12 and later.'

          def_node_search :cb_name?, '(send nil? :name str ...)'

          def on_new_investigation
            # handle an empty metdata.rb file
            return if processed_source.ast.nil?

            # Using range similar to RuboCop::Cop::Naming::Filename (file_name.rb)
            return if cb_name?(processed_source.ast)
            range = source_range(processed_source.buffer, 1, 0)
            add_offense(range, severity: :refactor) do |corrector|
              path = processed_source.path
              cb_name = File.basename(File.dirname(path))
              corrector.insert_before(processed_source.ast, "name '#{cb_name}'\n")
            end
          end
        end
      end
    end
  end
end
