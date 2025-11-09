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
      module Deprecations
        # The Librarian-Chef depsolving project is no longer maintained and a Cheffile should not be used for cookbook depsolving. Consider using Policyfiles instead.
        #
        # @example
        #
        #   ### incorrect
        #   require 'chefspec/librarian'
        #
        class LibrarianChefSpec < Base
          MSG = 'The Librarian-Chef depsolving project is no longer maintained and ChefSpec should not use Librarian-Chef for cookbook depsolving. Consider using Policyfiles instead.'
          RESTRICT_ON_SEND = [:require].freeze

          def on_send(node)
            return unless node.arguments.first == s(:str, 'chefspec/librarian')

            add_offense(node, severity: :warning)
          end
        end
      end
    end
  end
end
