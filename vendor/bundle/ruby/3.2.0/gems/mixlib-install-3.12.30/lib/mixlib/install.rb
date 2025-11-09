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

require "mixlib/versioning"
require "mixlib/shellout" unless defined?(Mixlib::ShellOut)

require_relative "install/backend"
require_relative "install/options"
require_relative "install/generator"
require_relative "install/generator/bourne"
require_relative "install/generator/powershell"
require_relative "install/dist"

module Mixlib
  class Install

    attr_reader :options

    def initialize(options = {})
      @options = Options.new(options)
    end

    #
    # Fetch artifact metadata information
    #
    # @return [Array<ArtifactInfo>] list of fetched artifact data for the configured
    # channel, product name, and product version.
    # @return [ArtifactInfo] fetched artifact data for the configured
    # channel, product name, product version and platform info
    def artifact_info
      Backend.info(options)
    end

    #
    # List available versions
    #
    # @return [Array<String>] list of available versions for the given
    # product_name and channel.
    def available_versions
      self.class.available_versions(options.product_name, options.channel)
    end

    #
    # List available versions
    #
    # @param [String] product name
    #
    # @param [String, Symbol] channel
    #
    # @return [Array<String>] list of available versions for the given
    # product_name and channel.
    def self.available_versions(product_name, channel)
      Backend.available_versions(
        Mixlib::Install::Options.new(
          product_name: product_name,
          channel: channel.to_sym
        )
      )
    end

    #
    # Returns an install script for the given options
    #
    # @return [String] script for installing with given options
    #
    def install_command
      Generator.install_command(options)
    end

    #
    # Download a single artifact
    #
    # @param [String] download directory. Default: Dir.pwd
    #
    # @return [String] file path of downloaded artifact
    #
    def download_artifact(directory = Dir.pwd)
      if options.platform.nil? || options.platform_version.nil? || options.architecture.nil?
        raise "Must provide platform options to download a specific artifact"
      end

      artifact = artifact_info

      FileUtils.mkdir_p directory
      file = File.join(directory, File.basename(artifact.url))

      uri = URI.parse(artifact.url)
      Net::HTTP.start(uri.host) do |http|
        resp = http.get(uri.path)
        open(file, "wb") do |io|
          io.write(resp.body)
        end
      end

      file
    end

    #
    # Returns the base installation directory for the given options
    #
    # @return [String] the installation directory for the project
    #
    def root
      # This only works for chef and chefdk but they are the only projects
      # we are supporting as of now.
      if options.for_ps1?
        "$env:systemdrive\\#{Mixlib::Install::Dist::WINDOWS_INSTALL_DIR}\\#{options.product_name}"
      else
        "/opt/#{options.product_name}"
      end
    end

    #
    # Returns the current version of the installed product.
    # Returns nil if the product is not installed.
    #
    def current_version
      # Note that this logic does not work for products other than
      # chef & chefdk since version-manifest is created under the
      # install directory which can be different than the product name (e.g.
      # chef-server -> /opt/opscode). But this is OK for now since
      # chef & chefdk are the only supported products.
      version_manifest_file = if options.for_ps1?
                                "$env:systemdrive\\#{Mixlib::Install::Dist::WINDOWS_INSTALL_DIR}\\#{options.product_name}\\version-manifest.json"
                              else
                                "/opt/#{options.product_name}/version-manifest.json"
                              end

      if File.exist? version_manifest_file
        JSON.parse(File.read(version_manifest_file))["build_version"]
      end
    end

    #
    # Returns true if an upgradable version is available, false otherwise.
    #
    def upgrade_available?
      return true if current_version.nil?

      artifact = artifact_info
      artifact = artifact.first if artifact.is_a? Array
      available_ver = Mixlib::Versioning.parse(artifact.version)
      current_ver = Mixlib::Versioning.parse(current_version)
      (available_ver > current_ver)
    end

    #
    # Automatically set the platform options
    #
    def detect_platform
      options.set_platform_info(self.class.detect_platform)
      self
    end

    #
    # Returns a Hash containing the platform info options
    #
    def self.detect_platform
      output = if Gem.win_platform?
                 # For Windows we write the detect platform script and execute the
                 # powershell.exe program with Mixlib::ShellOut
                 Dir.mktmpdir do |d|
                   File.open(File.join(d, "detect_platform.ps1"), "w+") do |f|
                     f.puts detect_platform_ps1
                   end

                   # An update to most Windows versions > 2008r2 now sets the execution policy
                   # to disallow unsigned powershell scripts. This changes it for just this
                   # powershell session, which allows this to run even if the execution policy
                   # is set higher.
                   Mixlib::ShellOut.new("powershell.exe -NoProfile -file #{File.join(d, "detect_platform.ps1")}", :env => { "PSExecutionPolicyPreference" => "Bypass" }).run_command
                 end
               else
                 Mixlib::ShellOut.new(detect_platform_sh).run_command
               end

      platform_info = output.stdout.split

      {
        platform: platform_info[0],
        platform_version: platform_info[1],
        architecture: platform_info[2],
      }
    end

    #
    # Returns the platform_detection.sh script
    #
    def self.detect_platform_sh
      Mixlib::Install::Generator::Bourne.detect_platform_sh
    end

    #
    # Returns the platform_detection.ps1 script
    #
    def self.detect_platform_ps1
      Mixlib::Install::Generator::PowerShell.detect_platform_ps1
    end

    #
    # Returns the install.sh script
    # Supported context parameters:
    # ------------------
    # base_url [String]
    #   url pointing to the omnitruck to be queried by the script.
    #
    def self.install_sh(context = {})
      Mixlib::Install::Generator::Bourne.install_sh(context)
    end

    #
    # Returns the install.ps1 script
    # Supported context parameters:
    # ------------------
    # base_url [String]
    #   url pointing to the omnitruck to be queried by the script.
    #
    def self.install_ps1(context = {})
      Mixlib::Install::Generator::PowerShell.install_ps1(context)
    end
  end
end
