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
  module Chef
    # Common node helpers used for matching against Chef Infra Cookbooks
    module CookbookHelpers
      def resource_block_name_if_string(node)
        if looks_like_resource?(node) && node.children.first.arguments.first.respond_to?(:value)
          node.children.first.arguments.first.value
        end
      end

      # Match a particular resource
      #
      # @param [String] resource_name The name of the resource to match
      # @param [RuboCop::AST::Node] node The rubocop ast node to search
      #
      # @yield
      #
      def match_resource_type?(resource_name, node)
        return unless looks_like_resource?(node)
        # bail out if we're not in the resource we care about or nil was passed (all resources)
        yield(node) if node.children.first.method?(resource_name.to_sym)
      end

      # Match particular properties within a resource
      #
      # @param [Symbol, Array<Symbol>] resource_names The name of the resources to match
      # @param [String] property_names The name of the property to match (or action)
      # @param [RuboCop::AST::Node] node The rubocop ast node to search
      #
      # @yield
      #
      def match_property_in_resource?(resource_names, property_names, node)
        return unless looks_like_resource?(node)
        # bail out if we're not in the resource we care about or nil was passed (all resources)
        return unless resource_names.nil? || Array(resource_names).include?(node.children.first.method_name) # see if we're in the right resource

        resource_block = node.children[2] # the 3rd child is the actual block in the resource
        return unless resource_block # nil would be an empty block

        if resource_block.begin_type? # if begin_type we need to iterate over the children
          resource_block.children.each do |resource_blk_child|
            extract_send_types(resource_blk_child) do |p|
              yield(p) if symbolized_property_types(property_names).include?(p.method_name)
            end
          end
        else # there's only a single property to check
          extract_send_types(resource_block) do |p|
            yield(p) if symbolized_property_types(property_names).include?(p.method_name)
          end
        end
      end

      def method_arg_ast_to_string(ast)
        # a property without a value. This is totally bogus, but they exist
        return if ast.children[2].nil?
        # https://rubular.com/r/6uzOMd6WCHewOu
        m = ast.children[2].source.match(/^("|')(.*)("|')$/)
        m[2] unless m.nil?
      end

      private

      # @param [String, Array] property
      #
      # @return [Array]
      def symbolized_property_types(property)
        Array(property).map(&:to_sym)
      end

      #
      # given a node object does it look like a chef resource or not?
      # warning: currently this requires a resource with properties since we key off blocks and property-less resources look like methods
      #
      # @param [RuboCop::AST::Node] node AST object to test
      #
      # @return [boolean]
      #
      def looks_like_resource?(node)
        return false unless node.block_type? # resources are blocks if they have properties
        return false unless node.children.first.receiver.nil? # resource blocks don't have a receiver
        return false if node.send_node.arguments.first.is_a?(RuboCop::AST::SymbolNode) # resources have a string name. resource actions have symbols

        # bail if the block doesn't have a name a resource *generally* has a name.
        # This isn't 100% true with things like apt_update and build_essential, but we'll live
        # with that for now to avoid the false positives of getting stuck in generic blocks in resources
        return false if node.children.first.arguments.empty?

        # if we made it this far we're probably in a resource
        true
      end

      def extract_send_types(node)
        return if node.nil? # there are cases we can be passed an empty node
        case node.type
        when :send
          yield(node) if node.receiver.nil? # if it's not nil then we're not in a property foo we're in bar.foo
        when :block # ie: not_if { ruby_foo }
          yield(node)
        when :while
          extract_send_types(node.body) { |t| yield(t) }
        when :if
          node.branches.each { |n| extract_send_types(n) { |t| yield(t) } }
        when :case
          node.when_branches.each { |n| extract_send_types(n.body) { |t| yield(t) } } # unless node.when_branches.nil?
          extract_send_types(node.else_branch) { |t| yield(t) } if node.else_branch
        end
      end
    end
  end
end
