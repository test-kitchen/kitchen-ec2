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

require "erb" unless defined?(Erb)
require "ostruct" unless defined?(OpenStruct)
require_relative "../util"
require_relative "../dist"

module Mixlib
  class Install
    class Generator
      class Base
        attr_reader :options

        def initialize(options)
          @options = options
        end

        #
        # Returns the base path where the script fragments are located for
        # the generator as a String.
        #
        def self.script_base_path
          raise "You must define a script_base_path for your Generator::Base class."
        end

        #
        # Gets the contents of the given script.
        #
        def self.get_script(name, context = {})
          script_path = File.join(script_base_path, name)

          # If there is an erb template we render it, otherwise we just read
          # and return the contents of the script
          if File.exist? "#{script_path}.erb"
            # Default values to use incase they are not set in the context
            context[:project_name] ||= Mixlib::Install::Dist::PROJECT_NAME.freeze
            context[:base_url] ||= Mixlib::Install::Dist::OMNITRUCK_ENDPOINT.freeze
            context[:default_product] ||= Mixlib::Install::Dist::DEFAULT_PRODUCT.freeze
            context[:bug_url] ||= Mixlib::Install::Dist::BUG_URL.freeze
            context[:support_url] ||= Mixlib::Install::Dist::SUPPORT_URL.freeze
            context[:resources_url] ||= Mixlib::Install::Dist::RESOURCES_URL.freeze
            context[:macos_dir] ||= Mixlib::Install::Dist::MACOS_VOLUME.freeze
            context[:windows_dir] ||= Mixlib::Install::Dist::WINDOWS_INSTALL_DIR.freeze
            context[:user_agent_string] = Util.user_agent_string(context[:user_agent_headers])

            context_object = OpenStruct.new(context).instance_eval { binding }
            ERB.new(File.read("#{script_path}.erb")).result(context_object)
          else
            File.read(script_path)
          end
        end

        def get_script(name, context = {})
          self.class.get_script(name, context)
        end
      end
    end
  end
end
