# frozen_string_literal: true
#
# Copyright:: Copyright 2020, Chef Software Inc.
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
        # The use_automatic_resource_name method was removed in Chef Infra Client 16. The resource name/provides should be set explicitly instead.
        #
        # @example
        #
        #   ### incorrect
        #   module MyCookbook
        #     class MyCookbookService < Chef::Resource
        #       use_automatic_resource_name
        #       provides :mycookbook_service
        #
        #       # some additional code
        #     end
        #   end
        #
        class UseAutomaticResourceName < Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          MSG = 'The use_automatic_resource_name method was removed in Chef Infra Client 16. The resource name/provides should be set explicitly instead.'
          RESTRICT_ON_SEND = [:use_automatic_resource_name].freeze

          def on_send(node)
            add_offense(node.loc.selector, severity: :warning) do |corrector|
              corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
            end
          end
        end
      end
    end
  end
end
