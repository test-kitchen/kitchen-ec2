#
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "mixlib/versioning"
require_relative "dist"

module Mixlib
  class Install
    class Product
      def initialize(key, &block)
        @product_key = key
        instance_eval(&block)
      end

      DSL_PROPERTIES = [
        :config_file,
        :ctl_command,
        :product_key,
        :package_name,
        :product_name,
        :install_path,
        :omnibus_project,
        :github_repo,
        :downloads_product_page_url,
        :api_url,
      ]

      #
      # DSL methods can receive either a String or a Proc to calculate the
      # value of the property later on based on the version.
      # We error out if we get both the String and Proc, and we return the value
      # of the property if we do not receive anything.
      #
      # @param [String] prop_string
      #   value to be set in String form
      # @param [Proc] block
      #   value to be set in Proc form
      #
      # @return [String] value of the property
      #
      DSL_PROPERTIES.each do |prop|
        define_method prop do |prop_string = nil, &block|
          if block.nil?
            if prop_string.nil?
              value = instance_variable_get("@#{prop}".to_sym)
              return default_value_for(prop) if value.nil?

              if value.is_a?(String) || value.is_a?(Symbol)
                value
              else
                value.call(version_for(version))
              end
            else
              instance_variable_set("@#{prop}".to_sym, prop_string)
            end
          else
            raise "Can not use String and Proc at the same time for #{prop}." if !prop_string.nil?
            instance_variable_set("@#{prop}".to_sym, block)
          end
        end
      end

      #
      # Return the default values for DSL properties
      #
      def default_value_for(prop)
        case prop
        when :install_path
          "/opt/#{package_name}"
        when :omnibus_project
          package_name
        when :downloads_product_page_url
          "#{Mixlib::Install::Dist::DOWNLOADS_PAGE}/#{product_key}"
        when :github_repo
          "#{Mixlib::Install::Dist::GITHUB_ORG}/#{product_key}"
        when :api_url
          ENV.fetch("PACKAGE_ROUTER_ENDPOINT", Mixlib::Install::Dist::PRODUCT_ENDPOINT)
        else
          nil
        end
      end

      #
      # Return all known omnibus project names for a product
      #
      def known_omnibus_projects
        # iterate through min/max versions for all product names
        # and collect the name for both versions
        projects = %w{ 0.0.0 1000.1000.1000 }.collect do |v|
          @version = v
          omnibus_project
        end
        # remove duplicates and return multiple known names or return the single
        # project name
        projects.uniq || projects
      end

      #
      # Sets or retrieves the version for the product. This is used later
      # when we are reading the value of a property if a Proc is specified
      #
      def version(value = nil)
        if value.nil?
          @version
        else
          @version = value
        end
      end

      #
      # Helper method to convert versions from String to Mixlib::Version
      #
      # @param [String] version_string
      #   value to be set in String form
      #
      # @return [Mixlib::Version]
      def version_for(version_string)
        Mixlib::Versioning.parse(version_string)
      end
    end

    class ProductMatrix
      def initialize(&block)
        @product_map = {}
        instance_eval(&block)
      end

      #
      # The only DSL method of this class. It creates a Product with given
      # `key` and stores it.
      #
      def product(key, &block)
        @product_map[key] = Product.new(key, &block)
      end

      #
      # Fetches the keys of available products.
      #
      # @return Array[String] of keys
      def products
        @product_map.keys
      end

      #
      # Looks up a product and sets version on it to be used later by the
      # Product.
      #
      # @param [String] key
      #   Lookup key of the product.
      # @param [String] version
      #   Version to be set for the product. By default version is set to :latest
      #
      # @return [Product]
      def lookup(key, version = :latest)
        # return nil unless the product exists
        return nil unless @product_map.key?(key)

        product = @product_map[key]
        # We set the lookup version for the product to a very high number in
        # order to mimic :latest so that one does not need to handle this
        # symbol explicitly when constructing logic based on version numbers.
        version = "1000.1000.1000" if version.to_sym == :latest
        product.version(version)
        product
      end

      #
      # Looks up all products that are available on downloads.chef.io
      #
      # @return Hash{String => Product}
      #   :key => product_key
      #   :value => Mixlib::Install::Product instance
      def products_available_on_downloads_site
        @product_map.reject do |product_key, product|
          product.downloads_product_page_url == :not_available
        end
      end
    end
  end
end
