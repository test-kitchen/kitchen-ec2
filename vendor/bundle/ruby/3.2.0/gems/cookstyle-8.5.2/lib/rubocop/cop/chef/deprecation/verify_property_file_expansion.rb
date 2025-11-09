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
        # In Chef Infra Client 13 the "file" variable for use within the verify property was replaced with the "path" variable.
        #
        # @example
        #
        #   ### incorrect
        #   file '/etc/nginx.conf' do
        #     verify 'nginx -t -c %{file}'
        #   end
        #
        #   ### correct
        #   file '/etc/nginx.conf' do
        #     verify 'nginx -t -c %{path}'
        #   end
        #
        class VerifyPropertyUsesFileExpansion < Base
          include RuboCop::Chef::CookbookHelpers
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '12.5'

          MSG = "Use the 'path' variable in the verify property and not the 'file' variable which was removed in Chef Infra Client 13."

          def on_block(node)
            match_property_in_resource?(nil, 'verify', node) do |verify|
              return unless verify.source.match?(/%{file}/)
              add_offense(verify, severity: :warning) do |corrector|
                corrector.replace(verify.loc.expression, verify.loc.expression.source.gsub('%{file}', '%{path}'))
              end
            end
          end
        end
      end
    end
  end
end
