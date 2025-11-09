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
      module Deprecations
        # With the release of Chef Infra Client 12.14 and the yum cookbook 3.0 the actions the `yum_repository` resource actions were renamed. The `add` action became `create` and `delete` became `remove` to better match other resources in Chef Infra Client.
        #
        # @example
        #
        #   ### incorrect
        #   yum_repository 'OurCo' do
        #     description 'OurCo yum repository'
        #     baseurl 'http://artifacts.ourco.org/foo/bar'
        #     gpgkey 'http://artifacts.ourco.org/pub/yum/RPM-GPG-KEY-OURCO-6'
        #     action :add
        #   end
        #
        #   ### correct
        #   yum_repository 'OurCo' do
        #     description 'OurCo yum repository'
        #     baseurl 'http://artifacts.ourco.org/foo/bar'
        #     gpgkey 'http://artifacts.ourco.org/pub/yum/RPM-GPG-KEY-OURCO-6'
        #     action :create
        #   end
        #
        class DeprecatedYumRepositoryActions < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.14'

          MSG = 'With the release of Chef Infra Client 12.14 and the yum cookbook 3.0 several properties in the yum_repository resource the actions the yum_repository resource actions were renamed. The `add` action became `create` and `delete` became `remove` to better match other resources in Chef Infra Client.'

          def on_block(node)
            match_property_in_resource?(:yum_repository, 'action', node) do |prop_node|
              next unless prop_node.arguments.first.sym_type?
              next unless [s(:sym, :add), s(:sym, :delete)].include?(prop_node.arguments.first)

              add_offense(prop_node, severity: :warning) do |corrector|
                corrector.replace(prop_node, prop_node.source
                  .gsub('add', 'create')
                  .gsub('delete', 'remove'))
              end
            end
          end
        end
      end
    end
  end
end
