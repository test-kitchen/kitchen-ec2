# frozen_string_literal: true
#
# Copyright:: 2021, Chef Software, Inc.
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
        # Chef Infra Client 15.5 and later include cloud helpers to make detecting instances that run on public and private clouds easier.
        #
        # @example
        #
        #   ### incorrect
        #   node['cloud']['provider'] == 'alibaba'
        #   node['cloud']['provider'] == 'ec2'
        #   node['cloud']['provider'] == 'gce'
        #   node['cloud']['provider'] == 'rackspace'
        #   node['cloud']['provider'] == 'eucalyptus'
        #   node['cloud']['provider'] == 'linode'
        #   node['cloud']['provider'] == 'openstack'
        #   node['cloud']['provider'] == 'azure'
        #   node['cloud']['provider'] == 'digital_ocean'
        #   node['cloud']['provider'] == 'softlayer'
        #
        #   ### correct
        #   alibaba?
        #   ec2?
        #   gce?
        #   rackspace?
        #   eucalyptus?
        #   linode?
        #   openstack?
        #   azure?
        #   digital_ocean?
        #   softlayer?
        #
        class UseChefLanguageCloudHelpers < Base
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '15.5'

          MSG = 'Chef Infra Client 15.5 and later include cloud helpers to make detecting instances that run on public and private clouds easier.'
          RESTRICT_ON_SEND = [:==, :[]].freeze
          VALID_CLOUDS = %w(alibaba ec2 gce rackspace eucalyptus linode openstack azure digital_ocean softlayer).freeze

          def_node_matcher :provider_comparison?, <<-PATTERN
            (send
              (send
                (send
                  (send nil? :node) :[]
                  (str "cloud")) :[]
                (str "provider")) :==
              (str $_))
          PATTERN

          def_node_matcher :node_cloud?, <<-PATTERN
            (send
              (send nil? :node) :[]
              (str "cloud"))
          PATTERN

          def on_send(node)
            provider_comparison?(node) do |cloud_name|
              # skip it if someone was checking for a bogus cloud provider
              next unless VALID_CLOUDS.include?(cloud_name)

              # if they were checking for node['cloud'] and the provider replace it all
              node = node.parent if node.parent.and_type? && node_cloud?(node.left_sibling)

              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "#{cloud_name}?")
              end
            end
          end
        end
      end
    end
  end
end
