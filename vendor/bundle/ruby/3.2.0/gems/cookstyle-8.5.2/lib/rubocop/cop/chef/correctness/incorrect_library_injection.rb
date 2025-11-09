# frozen_string_literal: true
#
# Copyright:: Copyright 2019-2020, Chef Software Inc.
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
        # Libraries should be injected into the `Chef::DSL::Recipe` class and not `Chef::Recipe` or `Chef::Provider` classes directly.
        #
        # @example
        #
        #   ### incorrect
        #   ::Chef::Recipe.send(:include, Filebeat::Helpers)
        #   ::Chef::Provider.send(:include, Filebeat::Helpers)
        #   ::Chef::Recipe.include Filebeat::Helpers
        #   ::Chef::Provider.include Filebeat::Helpers
        #
        #   ### correct
        #   ::Chef::DSL::Recipe.send(:include, Filebeat::Helpers) # covers previous Recipe & Provider classes
        #
        class IncorrectLibraryInjection < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'Libraries should be injected into the Chef::DSL::Recipe class and not Chef::Recipe or Chef::Provider classes directly.'
          RESTRICT_ON_SEND = [:send, :include].freeze

          def_node_search :correct_injection?, <<-PATTERN
            {(send
               (const
                 (const
                   (const {cbase nil?} :Chef) :DSL) :Recipe) :send
               (sym :include)
             ... )
             (send
               (const
                 (const
                   (const {cbase nil?} :Chef) :DSL) :Recipe) :include
             ... )}
          PATTERN

          def_node_matcher :legacy_injection?, <<-PATTERN
            {(send (const (const {cbase nil?} :Chef) {:Recipe :Provider}) :send (sym :include) ... )
             (send (const (const {cbase nil?} :Chef) {:Recipe :Provider}) :include ... )}
          PATTERN

          def on_send(node)
            legacy_injection?(node) do
              add_offense(node, severity: :refactor) do |corrector|
                if node.parent && correct_injection?(node.parent)
                  corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
                else
                  corrector.replace(node,
                    node.source.gsub(/Chef::(Provider|Recipe)/, 'Chef::DSL::Recipe'))
                end
              end
            end
          end
        end
      end
    end
  end
end
