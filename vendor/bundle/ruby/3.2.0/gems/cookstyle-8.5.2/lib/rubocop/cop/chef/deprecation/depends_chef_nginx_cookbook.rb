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
      module Deprecations
        # Don't depend on the deprecated `chef_nginx` cookbook that was replaced by the `nginx` cookbook. The legacy chef_nginx cookbook may not be compatible with newer Chef Infra Client releases.
        #
        # @example
        #
        #   ### incorrect
        #   depends 'chef_nginx'
        #
        #   ### correct
        #   depends 'nginx'
        #
        class DependsOnChefNginxCookbook < Base
          include RangeHelp
          extend AutoCorrector

          MSG = "Don't depend on the deprecated `chef_nginx` cookbook that was replaced by the `nginx` cookbook."
          RESTRICT_ON_SEND = [:depends].freeze

          def_node_matcher :depends_compat_resource?, <<-PATTERN
            (send nil? :depends (str {"chef_nginx"}))
          PATTERN

          def on_send(node)
            depends_compat_resource?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
              end
            end
          end
        end
      end
    end
  end
end
