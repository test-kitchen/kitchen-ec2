#
# Author:: Thom May (<thom@chef.io>)
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

module Mixlib
  class Install
    class Util
      class << self
        # @return [String] a pretty/helpful representation of a Chef Omnibus
        #   package version
        # @api private
        def pretty_version(version)
          case version
          when "true" then "install only if missing"
          when "latest" then "always install latest version"
          else version
          end
        end

        # Builds a complete command given a variables String preamble and a file
        # containing shell code.
        #
        # @param vars [String] shell variables, as a String
        # @param file [String] file basename (without extension) containing
        #   shell code
        # @param powershell [Boolean] for powershell
        # @return [String] command
        # @api private
        def shell_code_from_file(vars, file, powershell, opts = {})
          src_file = file + (powershell ? ".ps1" : ".sh")

          Util.wrap_shell([vars, "", IO.read(src_file)].join("\n"),
                          powershell, opts)
        end

        # Wraps a body of shell code with common context appropriate for the type
        # of shell.
        #
        # @param code [String] the shell code to be wrapped
        # @param opts [Hash] options
        # @param opts[:http_proxy] [String] http proxy url
        # @param opts[:https_proxy] [String] https proxy url
        # @return [String] wrapped shell code
        # @api private
        def wrap_shell(code, powershell = false, opts = {})
          env = []
          if opts[:http_proxy]
            env << Util.shell_env_var("http_proxy", opts[:http_proxy], powershell)
            env << Util.shell_env_var("HTTP_PROXY", opts[:http_proxy], powershell)
          end
          if opts[:https_proxy]
            env << Util.shell_env_var("https_proxy", opts[:https_proxy], powershell)
            env << Util.shell_env_var("HTTPS_PROXY", opts[:https_proxy], powershell)
          end
          unless env.empty?
            code = env.join("\n").concat("\n").concat(code)
          end
          if powershell
            "\n" + code
          else
            Util.wrap_command(code)
          end
        end

        # Builds a shell environment variable assignment string for the
        # required shell type.
        #
        # @param name [String] variable name
        # @param value [String] variable value
        # @return [String] shell variable assignment
        # @api private
        def shell_env_var(name, value, powershell = false)
          if powershell
            shell_var("env:#{name}", value, true)
          else
            "#{shell_var(name, value)}; export #{name}"
          end
        end

        # Builds a shell variable assignment string for the required shell type.
        #
        # @param name [String] variable name
        # @param value [String] variable value
        # @param powershell [Boolean] for powershell
        # @return [String] shell variable assignment
        def shell_var(name, value, powershell = false)
          if powershell
            %{$#{name} = "#{value}"}
          else
            %{#{name}="#{value}"}
          end
        end

        # Generates a command (or series of commands) wrapped so that it can be
        # invoked on a remote instance or locally.
        #
        # This method uses the Bourne shell (/bin/sh) to maximize the chance of
        # cross platform portability on Unix-like systems.
        #
        # @param [String] the command
        # @return [String] a wrapped command string
        def wrap_command(cmd)
          cmd = "false" if cmd.nil?
          cmd = "true" if cmd.to_s.empty?
          cmd = cmd.sub(/\n\Z/, "") if cmd =~ /\n\Z/

          "sh -c '\n#{cmd}\n'"
        end

        # Build the user-agent string
        #
        # @param name [Array] headers
        # @return [String] generated user-agent string
        def user_agent_string(headers)
          require_relative "version"
          user_agents = %W{mixlib-install/#{Mixlib::Install::VERSION}}
          user_agents << headers
          # Ensure that if the default user agent is already set it doesn't get duplicated
          user_agents.flatten.compact.uniq.join(" ")
        end

        def map_windows_version(version)
          # This logic does not try to compare and determine proper versions based on conditions or ranges.
          # These are here to improve UX for desktop versions.
          case version
          when /^10/
            "2016"
          when /^6.3/, /^8.1/, /2016nano/
            "2012r2"
          when /^6.2/, /^8/
            "2012"
          when /^6.1/, /^7/
            "2008r2"
          when /^6/
            "2008"
          else
            version
          end
        end

        #
        # Normalizes architecture information
        #
        # @param [String] architecture
        #
        # @return String [architecture]
        def normalize_architecture(architecture)
          case architecture
          when "amd64"
            "x86_64"
          when "arm64"
            "aarch64"
          when "i86pc", "i686"
            "i386"
          when "sun4u", "sun4v"
            "sparc"
          else
            architecture
          end
        end
      end
    end
  end
end
