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

require_relative "../install"
require "thor" unless defined?(Thor)

module Mixlib
  class Install
    class Cli < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      desc "version", "print mixlib-install version"
      def version
        require_relative "version"
        say Mixlib::Install::VERSION
      end

      desc "list-versions PRODUCT_NAME CHANNEL", "list available version for a product/channel"
      def list_versions(product_name, channel)
        say Mixlib::Install.available_versions(product_name, channel).join("\n")
      end

      desc "download PRODUCT_NAME", "download an artifact"
      option :channel,
        default: :stable,
        aliases: ["-c"],
        enum: Mixlib::Install::Options::SUPPORTED_CHANNELS.map(&:to_s)
      option :version,
        default: :latest,
        aliases: ["-v"]
      option :directory,
        default: Dir.pwd,
        aliases: ["-d"]
      option :platform,
        aliases: ["-p"]
      option :platform_version,
        aliases: ["-l"]
      option :architecture,
        default: "x86_64",
        aliases: ["-a"],
        enum: Mixlib::Install::Options::SUPPORTED_ARCHITECTURES.map(&:to_s)
      option :platform_version_compat,
        desc: "Enable or disable platform version compatibility mode.
This will match the closest earlier version if the passed version is unavailable.
If no earlier version is found the earliest version available will be set.",
        type: :boolean,
        default: true
      option :url,
        desc: "Print download URL without downloading the file",
        type: :boolean
      option :attributes,
        desc: "Print artifact attributes",
        type: :boolean
      def download(product_name)
        # Set minimum options
        mixlib_install_options = {
          channel: options[:channel].to_sym,
          product_name: product_name,
          product_version: options[:version],
          platform_version_compatibility_mode: options[:platform_version_compat],
          architecture: options[:architecture],
        }.tap do |opt|
          opt[:platform] = options[:platform] if options[:platform]
          opt[:platform_version] = options[:platform_version] if options[:platform_version]
        end

        # auto detect platform options if not configured
        if options[:platform].nil? && options[:platform_version].nil?
          mixlib_install_options.merge!(Mixlib::Install.detect_platform)
        end

        installer = Mixlib::Install.new(mixlib_install_options)

        begin
          artifact = installer.artifact_info
        rescue Mixlib::Install::Backend::ArtifactsNotFound => e
          abort e.message
        end

        if options[:url]
          say artifact.url
        else
          say "Starting download #{artifact.url}"
          file = installer.download_artifact(options[:directory])
          say "Download saved to #{file}"
        end

        say JSON.pretty_generate(artifact.to_hash) if options[:attributes]
      end

      desc "install-script", "generate install bootstrap script for shell or powershell"
      option :endpoint,
        desc: "Alternate omnitruck endpoint"
      option :file,
        desc: "Write script to file",
        aliases: ["-o"]
      option :type,
        desc: "Install script type",
        aliases: ["-t"],
        default: "sh",
        enum: Mixlib::Install::Options::SUPPORTED_SHELL_TYPES.map(&:to_s)
      def install_script
        context = {}
        context[:base_url] = options[:endpoint] if options[:endpoint]
        script = eval("Mixlib::Install.install_#{options[:type]}(context)")
        if options[:file]
          File.open(options[:file], "w") { |io| io.write(script) }
          say "Script written to #{options[:file]}"
        else
          say script
        end
      end
    end
  end
end
