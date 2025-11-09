# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
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
        # There is no need to check if the chef_gem resource supports compile_time as Chef Infra Client 12.1 and later support the compile_time property.
        #
        # @example
        #
        #   ### incorrect
        #   chef_gem 'ultradns-sdk' do
        #     compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
        #     action :nothing
        #   end
        #
        #   chef_gem 'ultradns-sdk' do
        #     compile_time true if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
        #     action :nothing
        #   end
        #
        #   chef_gem 'ultradns-sdk' do
        #     compile_time true if respond_to?(:compile_time)
        #     action :nothing
        #   end
        #
        #   ### correct
        #   chef_gem 'ultradns-sdk' do
        #     compile_time true
        #     action :nothing
        #   end
        #
        class RespondToCompileTime < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.1'

          MSG = 'There is no need to check if the chef_gem resource supports compile_time as Chef Infra Client 12.1 and later support the compile_time property.'

          def_node_matcher :compile_time_method_defined?, <<-PATTERN
          (if
            {
              (send
              (const
                (const
                  (const nil? :Chef) :Resource) :ChefGem) :method_defined?
              (sym :compile_time))

              (send
                (send
                  (const
                    (const
                      (const nil? :Chef) :Resource) :ChefGem) :instance_methods
                  (false)) :include?
                (sym :compile_time))

              (send nil? :respond_to?
                (sym :compile_time))
            }
            (send nil? :compile_time
              $(_)) nil?)
          PATTERN

          def on_block(node)
            match_property_in_resource?(:chef_gem, 'compile_time', node) do |compile_time_property|
              compile_time_method_defined?(compile_time_property.parent) do |val|
                add_offense(compile_time_property.parent, severity: :refactor) do |corrector|
                  corrector.replace(compile_time_property.parent, "compile_time #{val.source}")
                end
              end
            end
          end
        end
      end
    end
  end
end
