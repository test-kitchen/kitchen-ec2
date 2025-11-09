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
      module Modernize
        # Use the cron_d resource that ships with Chef Infra Client 14.4+ instead of manually creating the file with template, file, or cookbook_file resources.
        #
        # @example
        #
        #   ### incorrect
        #   template '/etc/cron.d/backup' do
        #     source 'cron_backup_job.erb'
        #     owner 'root'
        #     group 'root'
        #     mode '644'
        #   end
        #
        #   cookbook_file '/etc/cron.d/backup' do
        #     owner 'root'
        #     group 'root'
        #     mode '644'
        #   end
        #
        #   file '/etc/cron.d/backup' do
        #     content '*/30 * * * * backup /usr/local/bin/backup_script.sh'
        #     owner 'root'
        #     group 'root'
        #     mode '644'
        #   end
        #
        #   file '/etc/cron.d/blogs' do
        #     action :delete
        #   end
        #
        #   file "/etc/cron.d/#{job_name}" do
        #     action :delete
        #   end
        #
        #   file File.join('/etc/cron.d', job) do
        #     action :delete
        #   end
        #
        #   file 'delete old cron job' do
        #     path '/etc/cron.d/backup'
        #     action :delete
        #   end
        #
        #   file 'delete old cron job' do
        #     path "/etc/cron.d/#{job}"
        #     action :delete
        #   end
        #
        #   file 'delete old cron job' do
        #     path ::File.join('/etc/cron.d', job)
        #     action :delete
        #   end
        #
        #   ### correct
        #   cron_d 'backup' do
        #     minute '1'
        #     hour '1'
        #     mailto 'sysadmins@example.com'
        #     command '/usr/local/bin/backup_script.sh'
        #   end
        #
        #   cron_d 'blogs' do
        #     action :delete
        #   end
        #
        class CronDFileOrTemplate < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion

          minimum_target_chef_version '14.4'

          MSG = 'Use the cron_d resource that ships with Chef Infra Client 14.4+ instead of manually creating the file with template, file, or cookbook_file resources'

          def_node_matcher :file_or_template?, <<-PATTERN
            (block
              (send nil? {:template :file :cookbook_file}
                {(str $_) | (dstr (str $_) ...) | (send _ _ (str $_) ...)})
              ...
            )
          PATTERN

          def on_block(node)
            file_or_template?(node) do |file_name|
              break unless file_name.start_with?(%r{/etc/cron\.d\b}i)
              add_offense(node, severity: :refactor)
            end

            match_property_in_resource?(%i(template file cookbook_file), 'path', node) do |code_property|
              # instead of using CookbookHelpers#method_arg_ast_to_string, walk the property's descendants
              # and check if their value contains '/etc/cron.d'
              # covers the case where the argument to the path property is provided via a method like File.join
              code_property.each_descendant do |d|
                add_offense(node, severity: :refactor) if d.respond_to?(:value) && d.value.match?(%r{/etc/cron\.d\b}i)
              end
            end
          end
        end
      end
    end
  end
end
