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
        # The sc_windows resource from the sc cookbook allowed for the creation of windows services on legacy Chef Infra Client releases. Chef Infra Client 14.0 and later includes :create, :delete, and :configure actions without the need for additional cookbook dependencies. See the windows_service documentation at https://docs.chef.io/resources/windows_service for additional details on creating services with the windows_service resource.
        #
        # @example
        #
        #   ### incorrect
        #   sc_windows 'chef-client' do
        #     path "C:\\opscode\\chef\\bin"
        #     action :create
        #   end
        #
        #   ### correct
        #   windows_service 'chef-client' do
        #     action :create
        #     binary_path_name "C:\\opscode\\chef\\bin"
        #   end
        #
        class WindowsScResource < Base
          extend TargetChefVersion

          minimum_target_chef_version '14.0'

          MSG = 'Chef Infra Client 14.0 and later includes :create, :delete, and :configure actions without the need for the sc cookbook dependency. See the windows_service documentation at https://docs.chef.io/resources/windows_service for additional details.'
          RESTRICT_ON_SEND = [:sc_windows].freeze

          def on_send(node)
            add_offense(node, severity: :refactor)
          end
        end
      end
    end
  end
end
