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
      module Correctness
        # Use `raise` to force Chef Infra Client to fail instead of using `Chef::Application.fatal`, which masks the full stack trace of the failure and makes debugging difficult.
        #
        # @example
        #
        #   ### incorrect
        #   Chef::Application.fatal!('Something horrible happened!')
        #
        #   ### correct
        #   raise "Something horrible happened!"
        #
        class ChefApplicationFatal < Base
          extend AutoCorrector

          MSG = 'Use raise to force Chef Infra Client to fail instead of using Chef::Application.fatal'
          RESTRICT_ON_SEND = [:fatal!].freeze

          def_node_matcher :application_fatal?, <<-PATTERN
            (send
              (const
                (const nil? :Chef) :Application) :fatal!
              $( ... ))
          PATTERN

          def on_send(node)
            application_fatal?(node) do |val|
              add_offense(node, severity: :refactor) do |corrector|
                corrector.replace(node, "raise(#{val.source})")
              end
            end
          end
        end
      end
    end
  end
end
