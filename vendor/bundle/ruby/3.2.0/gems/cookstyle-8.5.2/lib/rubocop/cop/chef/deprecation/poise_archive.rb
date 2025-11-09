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
      module Deprecations
        # The poise_archive resource in the deprecated poise-archive should be replaced with the archive_file resource found in Chef Infra Client 15+.
        #
        # @example
        #
        #   ### incorrect
        #   poise_archive 'https://example.com/myapp.tgz' do
        #     destination '/opt/my_app'
        #   end
        #
        #   ### correct
        #   archive_file 'https://example.com/myapp.tgz' do
        #     destination '/opt/my_app'
        #   end
        #
        class PoiseArchiveUsage < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          minimum_target_chef_version '15.0'

          MSG = 'The poise_archive resource in the deprecated poise-archive should be replaced with the archive_file resource found in Chef Infra Client 15+'
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :depends_poise_archive?, <<-PATTERN
            (send nil? :depends (str "poise-archive"))
          PATTERN

          def on_send(node)
            depends_poise_archive?(node) do
              add_offense(node, severity: :warning)
            end
          end

          def on_block(node)
            match_resource_type?(:poise_archive, node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
