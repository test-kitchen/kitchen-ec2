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
      module Modernize
        # It is not longer necessary respond_to?(:foo) or defined?(foo) in metadata. This was used to support new metadata methods in Chef 11 and early versions of Chef 12.
        #
        # @example
        #
        #   ### incorrect
        #   chef_version '>= 13' if respond_to?(:chef_version)
        #   chef_version '>= 13' if defined?(chef_version)
        #   chef_version '>= 13' unless defined?(Ridley::Chef::Cookbook::Metadata)
        #   if defined(chef_version)
        #     chef_version '>= 13'
        #   end
        #
        #   ### correct
        #   chef_version '>= 13'
        #
        class RespondToInMetadata < Base
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '12.15'

          MSG = 'It is no longer necessary to use respond_to? or defined? in metadata.rb in Chef Infra Client 12.15 and later'

          def on_if(node)
            if_respond_to?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                # When the if statement is if modifier like `foo if respond_to?(:foo)` then
                # node.if_branch is the actual method call we want to extract.
                # If a series of metadata methods are wrapped in an if statement then the content we want
                # is a block under the if statement and node.parent.if_branch can get us that block
                node = node.parent unless node.if_type?

                corrector.replace(node, node.if_branch.source)
              end
            end
          end

          def on_defined?(node)
            # When the if statement is if modifier like `foo if respond_to?(:foo)` then
            # node.if_branch is the actual method call we want to extract.
            # If a series of metadata methods are wrapped in an if statement then the content we want
            # is a block under the if statement and node.parent.if_branch can get us that block
            node = node.parent if node.parent.conditional? # we want the whole conditional statement
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.if_branch.source)
            end
          end

          def_node_matcher :if_respond_to?, <<~PATTERN
            (if (send nil? :respond_to? _ ) ... )
          PATTERN
        end
      end
    end
  end
end
