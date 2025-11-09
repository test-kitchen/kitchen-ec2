#
# Author:: Thom May (<thom@chef.io>)
# Author:: Patrick Wright (<patrick@chef.io>)
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

require_relative "util"
require_relative "generator/powershell"
require_relative "dist"
require "cgi"

module Mixlib
  class Install
    class ScriptGenerator
      attr_accessor :version

      attr_accessor :powershell

      attr_accessor :prerelease

      attr_accessor :nightlies

      attr_accessor :install_flags

      attr_accessor :endpoint

      attr_accessor :root

      attr_accessor :use_sudo

      attr_reader :sudo_command

      def sudo_command=(cmd)
        if cmd.nil?
          @use_sudo = false
        else
          @sudo_command = cmd
        end
      end

      attr_accessor :http_proxy
      attr_accessor :https_proxy

      attr_accessor :omnibus_url
      attr_accessor :install_msi_url

      VALID_INSTALL_OPTS = %w{omnibus_url
                              endpoint
                              http_proxy
                              https_proxy
                              install_flags
                              install_msi_url
                              nightlies
                              prerelease
                              project
                              root
                              use_sudo
                              sudo_command}

      def initialize(version, powershell = false, opts = {})
        @version = (version || "latest").to_s.downcase
        @powershell = powershell
        @http_proxy = nil
        @https_proxy = nil
        @install_flags = nil
        @prerelease = false
        @nightlies = false
        @endpoint = "metadata"
        @omnibus_url = "https://www.chef.io/chef/install.sh"
        @use_sudo = true
        @sudo_command = "sudo -E"

        @root = if powershell
                  "$env:systemdrive\\#{Mixlib::Install::Dist::WINDOWS_INSTALL_DIR}\\#{Mixlib::Install::Dist::DEFAULT_PRODUCT}"
                else
                  "#{Mixlib::Install::Dist::LINUX_INSTALL_DIR}/#{Mixlib::Install::Dist::DEFAULT_PRODUCT}"
                end

        parse_opts(opts)
      end

      def install_command
        vars = if powershell
                 install_command_vars_for_powershell
               else
                 install_command_vars_for_bourne
               end
        shell_code_from_file(vars)
      end

      private

      # Generates the install command variables for Bourne shell-based
      # platforms.
      #
      # @return [String] shell variable lines
      # @api private
      def install_command_vars_for_bourne
        flags = %w{latest true nightlies}.include?(version) ? "" : "-v #{CGI.escape(version)}"
        flags << " " << "-n" if nightlies
        flags << " " << "-p" if prerelease
        flags << " " << install_flags if install_flags

        [
          shell_var("chef_omnibus_root", root),
          shell_var("chef_omnibus_url", omnibus_url),
          shell_var("install_flags", flags.strip),
          shell_var("pretty_version", Util.pretty_version(version)),
          shell_var("sudo_sh", sudo("sh")),
          shell_var("version", version),
        ].join("\n")
      end

      # Generates the install command variables for PowerShell-based platforms.
      #
      # @param version [String] version string
      # @param metadata_url [String] The metadata URL for the Chef Omnitruck API server
      # @param omnibus_root [String] The base directory the project is installed to
      # @return [String] shell variable lines
      # @api private
      def install_command_vars_for_powershell
        d_flag = install_flags.nil? ? nil : install_flags.match(/-download_directory (\S+)/)
        download_directory = d_flag.nil? ? "$env:TEMP" : d_flag[1]
        [
          shell_var("chef_omnibus_root", root),
          shell_var("msi", "#{download_directory}\\chef-#{version}.msi"),
          shell_var("download_directory", download_directory),
        ].tap do |vars|
          if install_msi_url
            vars << shell_var("chef_msi_url", install_msi_url)
          else
            vars << shell_var("chef_metadata_url", windows_metadata_url)
            vars << shell_var("pretty_version", Util.pretty_version(version))
            vars << shell_var("version", version)
          end
        end.join("\n")
      end

      def validate_opts!(opt)
        err_msg = ["#{opt} is not a valid option",
                   "valid options are #{VALID_INSTALL_OPTS.join(" ")}"].join(",")
        raise ArgumentError, err_msg unless VALID_INSTALL_OPTS.include?(opt.to_s)
      end

      def parse_opts(opts)
        opts.each do |opt, setting|
          validate_opts!(opt)
          case opt.to_s
          when "project", "endpoint"
            self.endpoint = metadata_endpoint_from_project(setting)
          else
            send("#{opt.to_sym}=", setting)
          end
        end
      end

      def shell_code_from_file(vars)
        fn = File.join(
          File.dirname(__FILE__),
          %w{.. .. .. support},
          "install_command"
        )
        code = Util.shell_code_from_file(
          vars, fn, powershell,
          http_proxy: http_proxy, https_proxy: https_proxy
        )
        powershell ? powershell_prefix.concat(code) : code
      end

      # Prefixes the PowerShell install script with helpers and shell vars
      # to detect the platform version and architecture.
      #
      # @return [String] PowerShell helpers and shell vars for platform info
      def powershell_prefix
        [
          Mixlib::Install::Generator::PowerShell.get_script("helpers.ps1"),
          "$platform_architecture = Get-PlatformArchitecture",
          "$platform_version = Get-PlatformVersion",
        ].join("\n")
      end

      # Builds a shell variable assignment string for the required shell type.
      #
      # @param name [String] variable name
      # @param value [String] variable value
      # @return [String] shell variable assignment
      # @api private
      def shell_var(name, value)
        Util.shell_var(name, value, powershell)
      end

      # @return the correct Chef Omnitruck API metadata endpoint, based on project
      def metadata_endpoint_from_project(project = nil)
        if project.nil? || project.casecmp("chef") == 0
          "metadata"
        else
          "metadata-#{project.downcase}"
        end
      end

      def windows_metadata_url
        base = if omnibus_url =~ %r{/install.sh$}
                 "#{File.dirname(omnibus_url)}/"
               end

        url = "#{base}#{endpoint}"
        url << "?p=windows&m=$platform_architecture&pv=$platform_version"
        url << "&v=#{CGI.escape(version)}" unless %w{latest true nightlies}.include?(version)
        url << "&prerelease=true" if prerelease
        url << "&nightlies=true" if nightlies
        url
      end

      # Conditionally prefixes a command with a sudo command.
      #
      # @param command [String] command to be prefixed
      # @return [String] the command, conditionally prefixed with sudo
      # @api private
      def sudo(script)
        use_sudo ? "#{sudo_command} #{script}" : script
      end
    end
  end
end
