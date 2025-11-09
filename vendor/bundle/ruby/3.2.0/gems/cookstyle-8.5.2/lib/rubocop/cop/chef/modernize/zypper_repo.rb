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
        # The zypper_repo resource was renamed zypper_repository when it was added to Chef Infra Client 13.3.
        #
        # @example
        #
        #   ### incorrect
        #   zypper_repo 'apache' do
        #     baseurl 'http://download.opensuse.org/repositories/Apache'
        #     path '/openSUSE_Leap_42.2'
        #     type 'rpm-md'
        #     priority '100'
        #   end
        #
        #   ### correct
        #   zypper_repository 'apache' do
        #     baseurl 'http://download.opensuse.org/repositories/Apache'
        #     path '/openSUSE_Leap_42.2'
        #     type 'rpm-md'
        #     priority '100'
        #   end
        #
        class UsesZypperRepo < Base
          extend TargetChefVersion
          extend AutoCorrector

          minimum_target_chef_version '13.3'

          MSG = 'The zypper_repo resource was renamed zypper_repository when it was added to Chef Infra Client 13.3.'
          RESTRICT_ON_SEND = [:zypper_repo].freeze

          def on_send(node)
            add_offense(node, severity: :refactor) do |corrector|
              corrector.replace(node, node.source.gsub(/^zypper_repo/, 'zypper_repository'))
            end
          end
        end
      end
    end
  end
end
