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
        # The osx_config_profile resource was renamed to osx_profile. The new resource name should be used.
        #
        # @example
        #
        #   ### incorrect
        #   osx_config_profile 'Install screensaver profile' do
        #     profile 'screensaver/com.company.screensaver.mobileconfig'
        #   end
        #
        #   ### correct
        #   osx_profile 'Install screensaver profile' do
        #     profile 'screensaver/com.company.screensaver.mobileconfig'
        #   end
        #
        class OsxConfigProfileResource < Base
          extend AutoCorrector

          MSG = 'The osx_config_profile resource was renamed to osx_profile. The new resource name should be used.'
          RESTRICT_ON_SEND = [:osx_config_profile].freeze

          def on_send(node)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.source.gsub(/^osx_config_profile/, 'osx_profile'))
            end
          end
        end
      end
    end
  end
end
