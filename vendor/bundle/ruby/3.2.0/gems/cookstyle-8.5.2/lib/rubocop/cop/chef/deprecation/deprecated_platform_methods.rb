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
      module Deprecations
        # Use `provider_for_action` or provides instead of the deprecated `Chef::Platform` methods in resources, which were removed in Chef Infra Client 13.
        #
        # @example
        #
        #   ### incorrect
        #   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
        #   provider = Chef::Platform.provider_for_resource(resource, :create)
        #
        #   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
        #   provider = Chef::Platform.find_provider("ubuntu", "16.04", resource)
        #
        #   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
        #   provider = Chef::Platform.find_provider_for_node(node, resource)
        #
        #   Chef::Platform.set :platform => :mac_os_x, :resource => :package, :provider => Chef::Provider::Package::Homebrew
        #
        #   ### correct
        #   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
        #   provider = resource.provider_for_action(:create)
        #
        #   # provides :package, platform_family: 'mac_os_x'

        class DeprecatedPlatformMethods < Base
          MSG = 'Use provider_for_action or provides instead of the deprecated Chef::Platform methods in resources, which were removed in Chef Infra Client 13.'
          RESTRICT_ON_SEND = [:provider_for_resource, :find_provider, :find_provider_for_node, :set].freeze

          def_node_matcher :platform_method?, <<-PATTERN
            (send (const (const nil? :Chef) :Platform) {:provider_for_resource :find_provider :find_provider_for_node :set} ... )
          PATTERN

          def on_send(node)
            platform_method?(node) do
              add_offense(node, severity: :warning)
            end
          end
        end
      end
    end
  end
end
