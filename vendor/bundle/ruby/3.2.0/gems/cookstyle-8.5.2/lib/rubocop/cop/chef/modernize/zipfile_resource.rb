# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software, Inc.
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
        # Use the archive_file resource built into Chef Infra Client 15+ instead of the zipfile resource from the zipfile cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   zipfile "C:\file.zip" do
        #     path 'C:\expand_here'
        #   end
        #
        class ZipfileResource < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '15.0'

          MSG = 'Use the archive_file resource built into Chef Infra Client 15+ instead of the zipfile resource from the zipfile cookbook.'
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :depends_zipfile?, <<-PATTERN
            (send nil? :depends (str "zipfile"))
          PATTERN

          def on_send(node)
            depends_zipfile?(node) do
              add_offense(node, severity: :refactor)
            end
          end

          def on_block(node)
            match_resource_type?(:zipfile, node) do
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
