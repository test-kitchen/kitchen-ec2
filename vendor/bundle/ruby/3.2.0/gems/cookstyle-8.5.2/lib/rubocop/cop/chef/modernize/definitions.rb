# frozen_string_literal: true
#
# Copyright:: 2019, Chef Software, Inc.
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
        # In 2016 with Chef Infra Client 12.5 Custom Resources were introduced as a way of writing reusable resource code that could be shipped in cookbooks. Custom Resources offer many advantages of legacy Definitions including unit testing with ChefSpec, input validation, actions, common properties like not_if/only_if, and resource reporting.
        #
        class Definitions < Base
          include RuboCop::Chef::CookbookHelpers

          MSG = 'Legacy Chef Infra definitions should be rewritten as custom resources to take full advantage of the Chef Infra feature set.'

          def on_block(node)
            add_offense(node, severity: :refactor) if node.respond_to?(:method_name) && node.method?(:define)
          end
        end
      end
    end
  end
end
