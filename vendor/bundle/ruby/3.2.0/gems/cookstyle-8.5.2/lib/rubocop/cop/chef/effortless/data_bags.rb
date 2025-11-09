# frozen_string_literal: true
#
# Copyright:: Copyright 2019, Chef Software Inc.
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
      module Effortless
        # Data bags cannot be used with the Effortless Infra pattern
        #
        # @example
        #
        #   ### incorrect
        #   data_bag_item('admins', login)
        #   data_bag(data_bag_name)
        class CookbookUsesDatabags < Base
          MSG = 'Cookbook uses data bags, which cannot be used in the Effortless Infra pattern'
          RESTRICT_ON_SEND = [:data_bag, :data_bag_item].freeze

          def on_send(node)
            add_offense(node, severity: :refactor)
          end
        end
      end
    end
  end
end
