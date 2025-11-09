# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software Inc.
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
        # Use the archive_file resource built into Chef Infra Client 15+ instead of the libarchive_file resource from the libarchive cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'libarchive'
        #
        #   libarchive_file "C:\file.zip" do
        #     path 'C:\expand_here'
        #   end
        #
        #   ### correct
        #   archive_file "C:\file.zip" do
        #     path 'C:\expand_here'
        #   end
        #
        class LibarchiveFileResource < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '15.0'

          MSG = 'Use the archive_file resource built into Chef Infra Client 15+ instead of the libarchive file resource from the libarchive cookbook'
          RESTRICT_ON_SEND = [:libarchive_file, :notifies, :subscribes].freeze

          def_node_matcher :notification_property?, <<-PATTERN
            (send nil? {:notifies :subscribes} (sym _) $(...) (sym _))
          PATTERN

          def on_send(node)
            # The need for this goes away once https://github.com/rubocop/rubocop/pull/8365 is pulled into Cookstyle
            if node.method?(:libarchive_file)
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, node.source.gsub('libarchive_file', 'archive_file'))
              end
            end

            notification_property?(node) do |val|
              next unless val.str_content&.start_with?('libarchive_file')
              add_offense(val, severity: :refactor) do |corrector|
                corrector.replace(node, node.source.gsub('libarchive_file', 'archive_file'))
              end
            end
          end
        end
      end
    end
  end
end
