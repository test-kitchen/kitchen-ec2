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
      module Deprecations
        # In the cookbook search helper you need to use named parameters (key/value style) other than the first (type) and second (query string) values.
        #
        # @example
        #
        ### incorrect:
        #  search(:node, '*:*', 0, 1000, { :ip_address => ["ipaddress"] })
        #  search(:node, '*:*', 0, 1000)
        #  search(:node, '*:*', 0)

        ### correct
        #
        # query(:node, '*:*')
        #  search(:node, '*:*', start: 0, rows: 1000, filter_result: { :ip_address => ["ipaddress"] })
        #  search(:node, '*:*', start: 0, rows: 1000)
        #  search(:node, '*:*', start: 0)
        #
        class SearchUsesPositionalParameters < Base
          extend AutoCorrector

          MSG = "Don't use deprecated positional parameters in cookbook search queries."
          RESTRICT_ON_SEND = [:search].freeze

          NAMED_PARAM_LOOKUP_TABLE = [nil, nil, 'start', 'rows', 'filter_result'].freeze

          def_node_matcher :search_method?, <<-PATTERN
            (send nil? :search ... )
          PATTERN

          def on_send(node)
            search_method?(node) do
              add_offense(node, severity: :warning) do |corrector|
                corrector.replace(node, corrected_string(node))
              end if positional_arguments?(node)
            end
          end

          private

          VALID_TYPES = %i(send hash block_pass).freeze

          #
          # Are the arguments in the passed node object positional
          #
          # @param [RuboCop::AST::Node] node
          #
          # @return [Boolean]
          #
          def positional_arguments?(node)
            return false if node.arguments.count < 3
            node.arguments[2..-1].each do |arg|
              # hashes, blocks, or variable/methods are valid. Anything else is not
              return true unless VALID_TYPES.include?(arg.type)
            end
            false
          end

          #
          # Return the corrected search string
          #
          # @param [RuboCop::AST::Node] node
          #
          # @return [String]
          #
          def corrected_string(node)
            args = node.arguments.dup

            # If the 2nd argument is a String and not an Integer as a String
            # then it's the old sort field and we need to delete it. Same thing
            # goes for nil values here.
            args.delete_at(2) if (args[2].str_type? && !integer_like_val?(args[2])) || args[2].nil_type?

            "search(#{args.collect.with_index { |arg, i| hashify_argument(arg, i) }.join(', ')})"
          end

          #
          # lookup the position in NAMED_PARAM_LOOKUP_TABLE to create a new
          # hashified version of the query. Also convert Integer like Strings into Integers
          #
          # @param [RuboCop::AST::Node] arg
          # @param [Integer] position
          #
          # @return [String]
          #
          def hashify_argument(arg, position)
            hash_key = NAMED_PARAM_LOOKUP_TABLE[position]
            if hash_key
              # convert Integers stored as Strings into plain Integers
              if integer_like_val?(arg)
                "#{hash_key}: #{Integer(arg.value)}"
              else
                "#{hash_key}: #{arg.source}"
              end
            else
              arg.source
            end
          end

          #
          # Does this value look like an Integer (it's an integer or a string)
          #
          # @param [RuboCop::AST::Node] val
          #
          # @return [Boolean]
          #
          def integer_like_val?(val)
            Integer(val.value)
            true
          rescue
            false
          end
        end
      end
    end
  end
end
