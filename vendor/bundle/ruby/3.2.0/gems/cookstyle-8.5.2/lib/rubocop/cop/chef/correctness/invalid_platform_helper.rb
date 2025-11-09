# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
      module Correctness
        # Pass valid platforms to the `platform?` helper. See [Infra Language: Platform](https://docs.chef.io/infra_language/checking_platforms/#platform-values) for a list of many common platform values.
        #
        # @example
        #
        #   ### incorrect
        #   platform?('darwin')
        #   platform?('rhel')
        #   platform?('sles')
        #
        #   ### correct
        #   platform?('mac_os_x')
        #   platform?('redhat')
        #   platform?('suse')
        #
        class InvalidPlatformHelper < Base
          include ::RuboCop::Chef::PlatformHelpers

          MSG = 'Pass valid platforms to the platform? helper.'
          RESTRICT_ON_SEND = [:platform?].freeze

          def_node_matcher :platform_helper?, <<-PATTERN
            (send nil? :platform? $str*)
          PATTERN

          def on_send(node)
            platform_helper?(node) do |plat|
              plat.to_a.each do |p|
                add_offense(p, severity: :refactor) if INVALID_PLATFORMS.key?(p.value)
              end
            end
          end
        end
      end
    end
  end
end
