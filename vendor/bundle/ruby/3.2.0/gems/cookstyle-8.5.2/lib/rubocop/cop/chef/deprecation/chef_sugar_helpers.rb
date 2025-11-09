# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # Do not use legacy chef-sugar helper methods, which will not be moved into Chef Infra Client itself. For a complete set of chef-sugar helpers now shipping in Chef Infra Client itself see https://github.com/chef/chef/tree/main/chef-utils#getting-started
        #
        # @example
        #
        #   ### incorrect
        #   vagrant_key?
        #   vagrant_domain?
        #   vagrant_user?
        #   require_chef_gem
        #   best_ip_for(node)
        #   nexus?
        #   ios_xr?
        #   ruby_20?
        #   ruby_19?
        #   includes_recipe?('foo::bar')
        #   wrlinux?
        #   dev_null
        #   nexentacore_platform?
        #   opensolaris_platform?
        #   nexentacore?
        #   opensolaris?
        #
        class ChefSugarHelpers < Base
          MSG = 'Do not use legacy chef-sugar helper methods, which will not be moved into Chef Infra Client itself. For a complete set of chef-sugar helpers now shipping in Chef Infra Client itself see https://github.com/chef/chef/tree/main/chef-utils#getting-started'
          RESTRICT_ON_SEND = [:vagrant_key?, :vagrant_domain?, :vagrant_user?, :require_chef_gem, :best_ip_for, :nexus?, :ios_xr?, :ruby_20?, :ruby_19?, :includes_recipe?, :wrlinux?, :dev_null, :nexentacore_platform?, :opensolaris_platform?, :nexentacore?, :opensolaris?].freeze

          def on_send(node)
            add_offense(node, severity: :refactor)
          end
        end
      end
    end
  end
end
