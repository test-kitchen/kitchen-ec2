# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software Inc.
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
        # Some providers in resources override the provides? method, used to check whether they are a valid provider on the current platform. In Chef Infra Client 13, this will cause an error. Instead use `provides :SOME_PROVIDER_NAME` to register the provider.
        #
        # @example
        #
        #   ### incorrect
        #   def provides?
        #    true
        #   end
        #
        #   ### correct
        #   provides :SOME_PROVIDER_NAME
        #
        class ResourceOverridesProvidesMethod < Base
          MSG = "Don't override the provides? method in a resource provider. Use provides :SOME_PROVIDER_NAME instead. This will cause failures in Chef Infra Client 13 and later."

          def_node_search :calls_provides?, '(send nil? :provides ...)'

          def on_def(node)
            return unless node.method?(:provides?)

            add_offense(node, severity: :warning) unless calls_provides?(processed_source.ast)
          end
        end
      end
    end
  end
end
