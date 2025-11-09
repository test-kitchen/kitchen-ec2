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
        # use_inline_resources became the default in Chef Infra Client 13+ and no longer needs
        # to be called in resources
        #
        # @example
        #
        #   ### incorrect
        #   use_inline_resources
        #   use_inline_resources if defined?(use_inline_resources)
        #   use_inline_resources if respond_to?(:use_inline_resources)
        #
        class UseInlineResourcesDefined < Base
          include RangeHelp
          extend AutoCorrector

          MSG = 'use_inline_resources is now the default for resources in Chef Infra Client 13+ and does not need to be specified.'
          RESTRICT_ON_SEND = [:use_inline_resources].freeze

          def on_send(node)
            # don't alert on the use_inline_resources within the defined? check
            # that would result in 2 alerts on the same line and wouldn't be useful
            return if node.parent && node.parent.defined_type?

            # catch the full offense if the method is gated like this: use_inline_resources if defined?(use_inline_resources)
            if node.parent && node.parent.if_type? && %i(defined? respond_to?).include?(node.parent.children.first.method_name)
              node = node.parent
            end

            add_offense(node, severity: :warning) do |corrector|
              corrector.remove(range_with_surrounding_space(range: node.loc.expression, side: :left))
            end
          end
        end
      end
    end
  end
end
