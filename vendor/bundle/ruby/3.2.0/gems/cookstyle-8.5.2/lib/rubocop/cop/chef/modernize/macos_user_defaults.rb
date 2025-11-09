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
        # The mac_os_x_userdefaults resource was renamed to macos_userdefaults when it was added to Chef Infra Client 14.0. The new resource name should be used.
        #
        # @example
        #
        #   ### incorrect
        #   mac_os_x_userdefaults 'full keyboard access to all controls' do
        #     domain 'AppleKeyboardUIMode'
        #     global true
        #     value '2'
        #   end
        #
        #   ### correct
        #   macos_userdefaults 'full keyboard access to all controls' do
        #     domain 'AppleKeyboardUIMode'
        #     global true
        #     value '2'
        #   end
        #
        class MacOsXUserdefaults < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '14.0'

          MSG = 'The mac_os_x_userdefaults resource was renamed to macos_userdefaults when it was added to Chef Infra Client 14.0. The new resource name should be used.'
          RESTRICT_ON_SEND = [:mac_os_x_userdefaults].freeze

          def on_send(node)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.source.gsub(/^mac_os_x_userdefaults/, 'macos_userdefaults'))
            end
          end
        end
      end
    end
  end
end
