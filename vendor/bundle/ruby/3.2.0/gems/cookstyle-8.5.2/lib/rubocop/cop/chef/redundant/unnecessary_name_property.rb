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
      module RedundantCode
        # There is no need to define a property or attribute named :name in a resource as Chef Infra defines this on all resources by default.
        #
        # @example
        #
        #   ### incorrect
        #   property :name, String
        #   property :name, String, name_property: true
        #   attribute :name, kind_of: String
        #   attribute :name, kind_of: String, name_attribute: true
        #   attribute :name, name_attribute: true, kind_of: String
        #
        class UnnecessaryNameProperty < Base
          extend AutoCorrector

          MSG = 'There is no need to define a property or attribute named :name in a resource as Chef Infra defines this on all resources by default.'
          RESTRICT_ON_SEND = [:property, :attribute].freeze

          def_node_matcher :name_property?, <<-PATTERN
          (send nil? {:attribute :property}
            (sym :name)
            (const nil? :String)?
            (hash $...)?
          )
          PATTERN

          def on_send(node)
            name_property?(node) do |hash_vals|
              # It's perfectly valid to redefine the name property if you give it non-default values
              # We do this in a few of our core resources where we give it a default value of "" for nameless resources
              # If there are hash vals in this attribute/property compare them with the default keys and if there's anything
              # else return so we don't alert
              unless hash_vals.empty?
                hash_keys = hash_vals.first.map { |x| x.key.value }
                return unless (hash_keys - [:kind_of, :name_attribute, :name_property]).empty?
              end

              add_offense(node, severity: :refactor) do |corrector|
                corrector.remove(node.source_range)
              end
            end
          end
        end
      end
    end
  end
end
