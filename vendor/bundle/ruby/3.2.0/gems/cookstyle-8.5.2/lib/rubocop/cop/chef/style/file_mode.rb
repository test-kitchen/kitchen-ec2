# frozen_string_literal: true
#
# Copyright:: 2016, Noah Kantrowitz
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
        # Use strings to represent file modes to avoid confusion between octal and base 10 integer formats.
        #
        # @example
        #
        #   ### incorrect
        #   remote_directory '/etc/my.conf' do
        #     content 'some content'
        #     mode 0600
        #     action :create
        #   end
        #
        #   remote_directory 'handler' do
        #     source 'handlers'
        #     recursive true
        #     files_mode 644
        #     action :create
        #   end
        #
        #   ### correct
        #   remote_directory '/etc/my.conf' do
        #     content 'some content'
        #     mode '600'
        #     action :create
        #   end
        #
        #   remote_directory 'handler' do
        #     source 'handlers'
        #     recursive true
        #     files_mode '644'
        #     action :create
        #   end
        #
        class FileMode < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Use strings to represent file modes to avoid confusion between octal and base 10 integer formats'
          RESTRICT_ON_SEND = [:mode, :files_mode].freeze

          def_node_matcher :resource_mode?, <<-PATTERN
            (send nil? {:mode :files_mode} $int)
          PATTERN

          def on_send(node)
            resource_mode?(node) do |mode_int|
              add_offense(mode_int, severity: :refactor) do |corrector|
                # If it was an octal literal, make sure we write out the right number.
                replacement_base = octal?(mode_int) ? 8 : 10
                replacement_mode = mode_int.children.first.to_s(replacement_base)

                # we build our own escaped string instead of using .inspect because that way
                # we can use single quotes instead of the double quotes that .inspect adds
                corrector.replace(mode_int, "'#{replacement_mode}'")
              end
            end
          end

          private

          def octal?(node)
            node.source =~ /^0o?\d+/i
          end
        end
      end
    end
  end
end
