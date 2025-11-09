# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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
        # Chef Infra Client 15.3 and later include a new Unified Mode that simplifies the execution of resources by replace the traditional compile and converge phases with a single phase. Unified mode simplifies writing advanced resources and avoids confusing errors that often occur when mixing ruby and Chef Infra resources. Chef Infra Client 17.0 and later will begin warning that `unified_mode true` should be set in all resources to validate that they will continue to function in Chef Infra Client 18.0 (April 2022) when Unified Mode becomes the default.
        #
        # @example
        #
        #  ### incorrect
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         provides :ulimit_rule
        #
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        #  ### correct
        #   class Chef
        #     class Resource
        #       class UlimitRule < Chef::Resource
        #         provides :ulimit_rule
        #         unified_mode true
        #
        #         property :type, [Symbol, String], required: true
        #         property :item, [Symbol, String], required: true
        #
        #         # additional resource code
        #       end
        #     end
        #   end
        #
        class HWRPWithoutUnifiedTrue < Base
          extend TargetChefVersion

          minimum_target_chef_version '15.3'

          MSG = 'Set `unified_mode true` in Chef Infra Client 15.3+ HWRP style custom resources to ensure they work correctly in Chef Infra Client 18 (April 2022) when Unified Mode becomes the default.'

          def_node_matcher :HWRP?, <<-PATTERN
          (class
            (const nil? :Chef) nil?
            (class
              (const nil? :Resource) nil?
              $(class
                (const nil? ... )
                (const
                  (const nil? :Chef) :Resource)
                  (begin ... ))))
          PATTERN

          def_node_search :unified_mode?, '(send nil? :unified_mode ...)'

          def on_class(node)
            return if unified_mode?(processed_source.ast)
            HWRP?(node) do |inherit|
              add_offense(inherit, severity: :warning)
            end
          end
        end
      end
    end
  end
end
