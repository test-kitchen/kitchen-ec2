# frozen_string_literal: true
#
# Copyright:: 2020-2022, Chef Software, Inc.
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
      module RedundantCode
        # Use the `:create_if_missing` action instead of `not_if` with a `::File.exist(FOO)` check.
        #
        # @example
        #
        #   ### incorrect
        #   cookbook_file '/logs/foo/error.log' do
        #     source 'error.log'
        #     owner 'root'
        #     group 'root'
        #     mode '0644'
        #     not_if { ::File.exists?('/logs/foo/error.log') }
        #   end
        #
        #   remote_file 'Download file' do
        #     path '/foo/bar'
        #     source 'https://foo.com/bar'
        #     owner 'root'
        #     group 'root'
        #     mode '0644'
        #     not_if { ::File.exist?('/foo/bar') }
        #   end
        #
        #   ### correct
        #   cookbook_file '/logs/foo/error.log' do
        #     source 'error.log'
        #     owner 'root'
        #     group 'root'
        #     mode '0644'
        #     action :create_if_missing
        #   end
        #
        #   remote_file 'Download file' do
        #     path '/foo/bar'
        #     source 'https://foo.com/bar'
        #     owner 'root'
        #     group 'root'
        #     mode '0644'
        #     action :create_if_missing
        #   end
        #
        class UseCreateIfMissing < Base
          include RuboCop::Chef::CookbookHelpers
          extend AutoCorrector
          include RangeHelp

          MSG = 'Use the :create_if_missing action instead of not_if with a ::File.exist(FOO) check.'
          RESOURCES = %i(cookbook_file file remote_directory cron_d remote_file template).freeze

          def_node_matcher :file_exist_value, <<-PATTERN
          (send (const {nil? (cbase)} :File) {:exist? :exists?} $(...))
          PATTERN

          def_node_search :has_action?, '(send nil? :action ...)'

          def_node_search :create_action, '(send nil? :action $sym)'

          def_node_search :path_property_node, '(send nil? :path $...)'

          def on_block(node)
            match_property_in_resource?(RESOURCES, :not_if, node) do |prop|
              # if it's not a block type then it's not a ruby block with a file.exist
              return unless prop.block_type?

              file_exist_value(prop.body) do |exists_content| # check the contents of the ruby block that's passed
                # not an offense if:
                #   - The resource block name (the last arg of the send) doesn't match the exists check content
                #   - If a path property is used it doesn't match the exists check content
                return unless exists_content == node.send_node.last_argument ||
                              exists_content == path_property_node(node)&.first&.first

                # we have an action so check if it is :create. If that's the case we can replace that value
                # and delete the not_if line. Otherwise it's an action like :remove and while the whole resource
                # no longer makes sense that's not our problem here.
                create_action(node) do |create_action|
                  return unless create_action == s(:sym, :create)
                  add_offense(prop, severity: :refactor) do |corrector|
                    corrector.replace(create_action, ':create_if_missing')
                    corrector.remove(range_by_whole_lines(prop.source_range, include_final_newline: true))
                  end
                  return
                end

                # if we got this far we didn't return above when we had an action
                # so we can just replace the not_if line with a new :create_if_missing action
                add_offense(prop, severity: :refactor) do |corrector|
                  corrector.replace(prop, 'action :create_if_missing')
                end
              end
            end
          end
        end
      end
    end
  end
end
