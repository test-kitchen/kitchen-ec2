# frozen_string_literal: true
#
# Copyright:: 2020, Chef Software, Inc.
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
        # Pass an array of packages to package resources instead of iterating over an array of packages when using multi-package capable package subsystem such as apt, yum, chocolatey, dnf, or zypper. Multi-package installs are faster and simplify logs.
        #
        # @example
        #
        #   ### incorrect
        #   %w(bmon htop vim curl).each do |pkg|
        #     package pkg do
        #       action :install
        #     end
        #   end
        #
        #   ### correct
        #   package %w(bmon htop vim curl)
        #
        class UseMultipackageInstalls < Base
          extend AutoCorrector

          MSG = 'Pass an array of packages to package resources instead of iterating over an array of packages when using multi-package capable package subsystem such as apt, yum, chocolatey, dnf, or zypper. Multi-package installs are faster and simplify logs.'
          MULTIPACKAGE_PLATS = %w(debian redhat suse amazon fedora scientific oracle rhel ubuntu centos redhat).freeze

          def_node_matcher :platform_or_platform_family?, <<-PATTERN
            (send (send nil? :node) :[] (str {"platform" "platform_family"}) )
          PATTERN

          def_node_matcher :platform_helper?, <<-PATTERN
          (if
            (send nil? {:platform_family? :platform?} $... )
            $(block
              (send
                $(array ... ) :each)
              (args ... )
              {(block
                (send nil? :package
                  (lvar ... ))
                (args)
                (send nil? :action
                  (sym :install)))
                (send nil? :package
                    (lvar _))}) nil?)
          PATTERN

          def_node_search :package_array_install, <<-PATTERN
          $(block
            (send
              $(array ... ) :each)
            (args ... )
            {(block
              (send nil? :package
                (lvar ... ))
              (args)
              (send nil? :action
                (sym :install)))
              (send nil? :package
                  (lvar _))})
          PATTERN

          # see if all platforms in the when condition are multi-package compliant
          def multipackage_platforms?(condition_obj)
            condition_obj.all? do |p|
              # make sure it's a string (not a regex) and it's in the array
              p.str_type? && MULTIPACKAGE_PLATS.include?(p.value)
            end
          end

          def on_when(node)
            return unless platform_or_platform_family?(node.parent.condition) &&
                          multipackage_platforms?(node.conditions)
            return if node.body.nil? # don't blow up on empty whens

            package_array_install(node.body) do |install_block, pkgs|
              add_offense(install_block, severity: :refactor) do |corrector|
                corrector.replace(install_block, "package #{pkgs.source}")
              end
            end
          end

          def on_if(node)
            platform_helper?(node) do |plats, blk, _pkgs|
              return unless multipackage_platforms?(plats)

              add_offense(blk, severity: :refactor) do |corrector|
                package_array_install(blk) do |install_block, pkgs|
                  corrector.replace(install_block, "package #{pkgs.source}")
                end
              end
            end
          end
        end
      end
    end
  end
end
