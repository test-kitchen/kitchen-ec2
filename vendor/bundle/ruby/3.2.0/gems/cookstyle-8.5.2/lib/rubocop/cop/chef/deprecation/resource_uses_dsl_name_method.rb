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
        # Don't use the dsl_name method in a resource to find the name of the resource. Use the resource_name method instead. dsl_name was removed in Chef Infra Client 13 and will now result in an error.
        #
        # @example
        #
        #   ### incorrect
        #   my_resource = MyResource.dsl_name
        #
        #   ### correct
        #   my_resource = MyResource.resource_name
        #
        class ResourceUsesDslNameMethod < Base
          MSG = 'Use resource_name instead of the dsl_name method in resources. This will cause failures in Chef Infra Client 13 and later.'
          RESTRICT_ON_SEND = [:dsl_name].freeze

          def on_send(node)
            add_offense(node, severity: :warning)
          end

          # potential autocorrect is new_resource.updated_by_last_action true, but we need to actually see what class we were called from
          # this might not be worth it yet based on the number of these we'd run into and the false auto correct potential
        end
      end
    end
  end
end
