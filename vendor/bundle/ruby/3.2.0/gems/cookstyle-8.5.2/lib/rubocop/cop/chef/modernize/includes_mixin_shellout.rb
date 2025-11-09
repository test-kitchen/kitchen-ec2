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
      module Modernize
        # There is no need to include Chef::Mixin::ShellOut or Chef::Mixin::PowershellOut in resources or providers as this is already done by Chef Infra Client 12.4+.
        #
        # @example
        #
        #   ### incorrect
        #   require 'chef/mixin/shell_out'
        #   include Chef::Mixin::ShellOut
        #   require 'chef/mixin/powershell_out'
        #   include Chef::Mixin::PowershellOut
        #
        class IncludingMixinShelloutInResources < Base
          extend AutoCorrector
          include RangeHelp

          MSG = 'There is no need to include Chef::Mixin::ShellOut or Chef::Mixin::PowershellOut in resources or providers as this is already done by Chef Infra Client 12.4+.'
          RESTRICT_ON_SEND = [:include, :require].freeze

          def_node_matcher :include_shellout?, <<-PATTERN
            (send nil? :include (const (const (const nil? :Chef) :Mixin) {:ShellOut :PowershellOut}))
          PATTERN

          def_node_matcher :require_shellout?, <<-PATTERN
            (send nil? :require ( str {"chef/mixin/shell_out" "chef/mixin/powershell_out"} ))
          PATTERN

          def_node_search :hwrp_classes?, <<-PATTERN
            (class
              (const ... )
              {(const
                (const
                  (const nil? :Chef) :Provider) :LWRPBase)
               (const
                 (const nil? :Chef) :Provider)
               }
              ...)
          PATTERN

          def check_for_offenses(node)
            containing_dir = File.basename(File.dirname(processed_source.path))

            # only add offenses when we're in a custom resource or HWRP, but not a plain old library
            if containing_dir == 'resources' || hwrp_classes?(processed_source.ast)
              add_offense(node, severity: :refactor) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end

          def on_send(node)
            require_shellout?(node) do
              check_for_offenses(node)
            end

            include_shellout?(node) do
              check_for_offenses(node)
            end
          end
        end
      end
    end
  end
end
