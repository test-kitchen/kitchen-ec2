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
      module Sharing
        # Metadata contains default maintainer information from the `chef generate cookbook` command. This should be updated to reflect that actual maintainer of the cookbook.
        #
        # @example
        #
        #   ### incorrect
        #   maintainer 'YOUR_COMPANY_NAME'
        #   maintainer_email 'YOUR_EMAIL'
        #   maintainer 'The Authors'
        #   maintainer_email 'you@example.com'
        #   ### correct
        #   maintainer 'Bob Bobberson'
        #   maintainer_email 'bob@bobberson.com'
        #
        class DefaultMetadataMaintainer < Base
          MSG = 'Metadata contains default maintainer information from the cookbook generator. Add actual cookbook maintainer information to the metadata.rb.'
          RESTRICT_ON_SEND = [:maintainer, :maintainer_email].freeze

          def_node_matcher :default_metadata?, '(send nil? {:maintainer :maintainer_email} (str {"YOUR_COMPANY_NAME" "The Authors" "YOUR_EMAIL" "you@example.com"}))'

          def on_send(node)
            default_metadata?(node) do
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
