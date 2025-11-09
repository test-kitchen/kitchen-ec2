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
  module Cop
    module Chef
      module Sharing
        # Resources should include examples field to allow automated documentation. Requires Chef Infra Client 13.9 or later.
        #
        # @example
        #
        #   ### correct
        #   examples <<~DOC
        #     **Specify a global domain value**
        #
        #     ```ruby
        #     macos_userdefaults 'full keyboard access to all controls' do
        #       key 'AppleKeyboardUIMode'
        #       value '2'
        #     end
        #     ```
        #   DOC
        #
        class IncludeResourceExamples < Base
          include RangeHelp
          extend TargetChefVersion

          minimum_target_chef_version '13.9'

          MSG = 'Resources should include examples field to allow automated documentation. Requires Chef Infra Client 13.9 or later.'

          def on_new_investigation
            return if processed_source.blank? || resource_examples(processed_source.ast).any?

            # Using range similar to RuboCop::Cop::Naming::Filename (file_name.rb)
            range = source_range(processed_source.buffer, 1, 0)

            add_offense(range, severity: :refactor)
          end

          def_node_search :resource_examples, '(send nil? :examples dstr ...)'
        end
      end
    end
  end
end
