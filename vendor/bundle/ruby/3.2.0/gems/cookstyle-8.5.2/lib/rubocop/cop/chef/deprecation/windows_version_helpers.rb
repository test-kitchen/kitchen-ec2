# frozen_string_literal: true
#
# Copyright:: 2019-2020, Chef Software, Inc.
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
        # Use node['platform_version'] and node['kernel'] data instead of the deprecated Windows::VersionHelper helpers from the Windows cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   Windows::VersionHelper.nt_version
        #   Windows::VersionHelper.server_version?
        #   Windows::VersionHelper.core_version?
        #   Windows::VersionHelper.workstation_version?
        #
        #   ### correct
        #   node['platform_version'].to_f
        #   node['kernel']['product_type'] == 'Server'
        #   node['kernel']['server_core']
        #   node['kernel']['product_type'] == 'Workstation'
        #
        class WindowsVersionHelpers < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '14.0'

          MSG = "Use node['platform_version'] and node['kernel'] data introduced in Chef Infra Client 14 instead of the deprecated Windows::VersionHelper helpers from the Windows cookbook."
          RESTRICT_ON_SEND = [:nt_version, :server_version?, :core_version?, :workstation_version?].freeze

          def_node_matcher :windows_helper?, <<-PATTERN
            (send ( const ( const {nil? cbase} :Windows ) :VersionHelper ) $_ )
          PATTERN

          def on_send(node)
            windows_helper?(node) do |method|
              add_offense(node, severity: :refactor) do |corrector|
                case method
                when :nt_version
                  corrector.replace(node, 'node[\'platform_version\'].to_f')
                when :server_version?
                  corrector.replace(node, 'node[\'kernel\'][\'product_type\'] == \'Server\'')
                when :core_version?
                  corrector.replace(node, 'node[\'kernel\'][\'server_core\']')
                when :workstation_version?
                  corrector.replace(node, 'node[\'kernel\'][\'product_type\'] == \'Workstation\'')
                end
              end
            end
          end
        end
      end
    end
  end
end
