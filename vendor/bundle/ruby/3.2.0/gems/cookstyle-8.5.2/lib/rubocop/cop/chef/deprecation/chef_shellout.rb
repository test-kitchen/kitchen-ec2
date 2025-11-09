# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software Inc.
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
        # Don't use the deprecated `Chef::ShellOut` class which was removed in Chef Infra Client 13. Use the `Mixlib::ShellOut` class instead, which behaves identically or convert to the simpler `shell_out` helper.
        #
        # @example
        #
        #   ### incorrect
        #   include Chef::ShellOut
        #   require 'chef/shellout'
        #   Chef::ShellOut.new('some_command')
        #
        #   ### correct
        #   include Mixlib::ShellOut
        #   require 'mixlib/shellout'
        #   Mixlib::ShellOut.new('some_command')
        #
        class ChefShellout < Base
          include RangeHelp
          extend AutoCorrector

          MSG = "Don't use the deprecated `Chef::ShellOut` class which was removed in Chef Infra Client 13. Use the `Mixlib::ShellOut` class instead, which behaves identically."
          RESTRICT_ON_SEND = [:new, :require, :include].freeze

          def_node_matcher :include_shellout?, <<-PATTERN
          (send nil? :include
            (const
              (const nil? :Chef) :ShellOut))
          PATTERN

          def_node_matcher :require_shellout?, <<-PATTERN
          (send nil? :require (str "chef/shellout"))
          PATTERN

          def_node_matcher :shellout_new?, <<-PATTERN
          (send
            (const
              (const nil? :Chef) :ShellOut) :new
              ... )
          PATTERN

          def on_send(node)
            include_shellout?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end

            require_shellout?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end

            shellout_new?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.replace(node, node.source.gsub('Chef::ShellOut', 'Mixlib::ShellOut'))
              end
            end
          end
        end
      end
    end
  end
end
