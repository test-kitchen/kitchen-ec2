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
        # Resources written in the class based HWRP style should inherit from the 'Chef::Resource' class and not the 'ChefCompat::Resource' class from the deprecated compat_resource cookbook.
        #
        # @example
        #
        #  ### incorrect
        #  class AptUpdate < ChefCompat::Resource
        #    # some resource code
        #  end
        #
        #  ### correct
        #  class AptUpdate < Chef::Resource
        #    # some resource code
        #  end
        #
        #  # better
        #  Write a custom resource using the custom resource DSL and avoid class based HWRPs entirely
        #
        class ResourceInheritsFromCompatResource < Base
          extend AutoCorrector

          MSG = "HWRP style resource should inherit from the 'Chef::Resource' class and not the 'ChefCompat::Resource' class from the deprecated compat_resource cookbook."

          def_node_matcher :inherits_from_compat_resource?, <<-PATTERN
          (class (const nil? _ ) (const (const nil? :ChefCompat) :Resource) ... )
          PATTERN

          def on_class(node)
            inherits_from_compat_resource?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.replace(node, node.source.gsub('ChefCompat', 'Chef'))
              end
            end
          end
        end
      end
    end
  end
end
