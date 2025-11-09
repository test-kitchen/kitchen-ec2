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
        # Neither Policyfiles or Effortless Infra which is based on Policyfiles supports Chef Infra Roles
        #
        # @example
        #
        #   ### incorrect
        #   node.role?('web_server')
        #   node.roles.include?('web_server')
        #
        class CookbookUsesRoles < Base
          MSG = 'Cookbook uses roles, which cannot be used in Policyfiles or Effortless Infra'
          RESTRICT_ON_SEND = [:role?, :roles].freeze

          def on_send(node)
            if node.receiver &&
               node.receiver.send_type? &&
               node.receiver.method?(:node)
              add_offense(node, severity: :refactor)
            end
          end
        end
      end
    end
  end
end
