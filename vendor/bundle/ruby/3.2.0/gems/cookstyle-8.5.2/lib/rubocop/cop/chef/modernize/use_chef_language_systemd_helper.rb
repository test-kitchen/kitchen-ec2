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
        # Chef Infra Client 15.5 and later include a `systemd?` helper for checking if a Linux system uses systemd.
        #
        # @example
        #
        #   ### incorrect
        #   node['init_package'] == 'systemd'
        #
        #   ### correct
        #   systemd?
        #
        class UseChefLanguageSystemdHelper < Base
          extend AutoCorrector
          extend TargetChefVersion

          minimum_target_chef_version '15.5'

          MSG = 'Chef Infra Client 15.5 and later include a `systemd?` helper for checking if a Linux system uses systemd.'
          RESTRICT_ON_SEND = [:==].freeze

          def_node_matcher :node_init_package?, <<-PATTERN
              (send
                (send
                  (send nil? :node) :[]
                  (str "init_package")) :==
                (str "systemd"))
            PATTERN

          def on_send(node)
            node_init_package?(node) do |_cloud_name|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, 'systemd?')
              end
            end
          end
        end
      end
    end
  end
end
