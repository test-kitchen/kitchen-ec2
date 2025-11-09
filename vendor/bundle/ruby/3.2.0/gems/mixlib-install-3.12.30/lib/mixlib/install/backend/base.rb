#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2016-2018 Chef Software, Inc.
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

require_relative "../util"

module Mixlib
  class Install
    class Backend
      class ArtifactsNotFound < StandardError; end

      class Base
        attr_reader :options

        def initialize(options)
          @options = options
        end

        #
        # Returns the list of artifacts from the configured backend based on the
        # configured product_name, product_version and channel.
        #
        # @abstract Subclasses should define this method.
        #
        # @return Array<ArtifactInfo>
        #   List of ArtifactInfo objects for the available artifacts.
        def available_artifacts
          raise "Must implement available_artifacts method that returns Array<ArtifactInfo>"
        end

        #
        # Returns the list of available versions for a given product_name
        # and channel.
        #
        # @abstract Subclasses should define this method.
        #           Currently this method is only available in the Artifactory
        #           subclass.
        #
        # @return Array<String>
        #   List of available versions as strings.
        def available_versions
          raise "available_versions API is only available for Artifactory backend."
        end

        #
        # See #filter_artifacts
        def info
          filter_artifacts(available_artifacts)
        end

        #
        # Returns true if platform filters are available, false otherwise.
        #
        # Note that we assume #set_platform_info method is used on the Options
        # class to set the platform options.
        #
        # @return TrueClass, FalseClass
        def platform_filters_available?
          !options.platform.nil?
        end

        #
        # Filters and returns the available artifacts based on the configured
        # platform filtering options.
        #
        # @return ArtifactInfo, Array<ArtifactInfo>, ArtifactsNotFound
        #   If the result is a single artifact, this returns ArtifactInfo.
        #   If the result is a list of artifacts, this returns Array<ArtifactInfo>.
        #   If no suitable artifact is found, this returns ArtifactsNotFound exception.
        def filter_artifacts(artifacts)
          return artifacts unless platform_filters_available?

          # First filter the artifacts based on the platform and architecture
          artifacts.select! do |a|
            a.platform == options.platform && a.architecture == options.architecture
          end

          # Now we are going to filter based on platform_version.
          # We will return the artifact with an exact match if available.
          # Otherwise we will search for a compatible artifact and return it
          # if the compat options is set.
          closest_compatible_artifact = nil

          artifacts.each do |a|
            return a if a.platform_version == options.platform_version

            # Calculate the closest compatible version.
            # For an artifact to be compatible it needs to be smaller than the
            # platform_version specified in options.
            # To find the closest compatible one we keep a max of the compatible
            # artifacts.

            # Remove "r2" from artifacts produced for windows since platform
            # versions with that ending break `to_f` comparisons.
            current_platform_version = a.platform_version.chomp("r2").to_f

            if closest_compatible_artifact.nil? ||
                (current_platform_version > closest_compatible_artifact.platform_version.to_f &&
                  current_platform_version < options.platform_version.to_f )
              closest_compatible_artifact = a
            end
          end

          # If the compat flag is set and if we have found a compatible artifact
          # we are going to use it.
          if options.platform_version_compatibility_mode && closest_compatible_artifact
            return closest_compatible_artifact
          end

          # Return an exception if we get to the end of the method
          raise ArtifactsNotFound, <<-EOF
No artifacts found matching criteria.
  product name: #{options.product_name}
  channel: #{options.channel}
  version: #{options.product_version}
  platform: #{options.platform}
  platform version: #{options.original_platform_version}
  architecture: #{options.architecture}
  compatibility mode: #{options.platform_version_compatibility_mode}
EOF
        end

        # On windows, if we do not have a native 64-bit package available
        # in the discovered artifacts, we will make 32-bit artifacts available
        # for 64-bit architecture.
        #
        # We also create new artifacts for windows 7, 8, 8.1 and 10
        #
        def windows_artifact_fixup!(artifacts)
          new_artifacts = [ ]
          native_artifacts = [ ]

          # We only return appx packages when a nano platform version is requested.
          if options.class::SUPPORTED_WINDOWS_NANO_VERSIONS.include?(options.original_platform_version)
            return artifacts.find_all { |a| a.appx_artifact? }

          # Otherwise, we only return msi artifacts and remove all appx packages
          else
            artifacts.delete_if { |a| a.appx_artifact? }
          end

          artifacts.each do |r|
            next if r.platform != "windows"

            # Store all native 64-bit artifacts and clone 32-bit artifacts to
            # be used as 64-bit.
            case r.architecture
            when "i386"
              new_artifacts << r.clone_with(architecture: "x86_64")
            when "x86_64"
              native_artifacts << r.clone
            else
              puts "Unknown architecture '#{r.architecture}' for windows."
            end
          end

          # Grab windows artifact for each architecture so we don't have to manipulate
          # the architecture extension in the filename of the url which changes based on product.
          # Don't want to deal with that!
          artifact_64 = artifacts.find { |a| a.platform == "windows" && a.architecture == "x86_64" }
          artifact_32 = artifacts.find { |a| a.platform == "windows" && a.architecture == "i386" }

          # Clone an existing 64-bit artifact
          new_artifacts.concat(clone_windows_desktop_artifacts(artifact_64)) if artifact_64
          # Clone an existing 32-bit artifact
          new_artifacts.concat(clone_windows_desktop_artifacts(artifact_32)) if artifact_32
          # Clone the 32 bit artifact when 64 bit doesn't exist
          new_artifacts.concat(clone_windows_desktop_artifacts(artifact_32, architecture: "x86_64")) if artifact_32 && !artifact_64

          # Now discard the cloned artifacts if we find an equivalent native
          # artifact
          native_artifacts.each do |r|
            new_artifacts.delete_if do |x|
              x.platform_version == r.platform_version
            end
          end

          # add the remaining cloned artifacts to the original set
          artifacts += new_artifacts
        end

        #
        # Normalizes platform and platform_version information that we receive.
        # There are a few entries that we historically published
        # that we need to normalize. They are:
        #   * solaris -> solaris2 & 10 -> 5.10 for solaris.
        #
        # @param [String] platform
        # @param [String] platform_version
        #
        # @return Array<String> [platform, platform_version]
        def normalize_platform(platform, platform_version)
          if platform == "solaris"
            platform = "solaris2"

            # Here platform_version is set to either 10 or 11 and we would like
            # to normalize that to 5.10 and 5.11.
            platform_version = "5.#{platform_version}"
          end

          [platform, platform_version]
        end

        private

        #
        # Custom map Chef's supported windows desktop versions to the server versions we currently build
        # See https://docs.chef.io/platforms.html
        #
        def map_custom_windows_desktop_versions(desktop_version)
          server_version = Util.map_windows_version(desktop_version)

          # Windows desktop 10 officially maps to server 2016.
          # However, we don't test on server 2016 at this time, so we default to 2012r2
          server_version = "2012r2" if server_version == "2016"

          server_version
        end

        #
        # Clone all supported Windows desktop artifacts from a base artifact
        # options hash allows overriding any valid attribute
        #
        def clone_windows_desktop_artifacts(base_artifact, options = {})
          @options.class::SUPPORTED_WINDOWS_DESKTOP_VERSIONS.collect do |dv|
            options[:platform_version] = dv
            options[:url] = base_artifact.url.gsub("\/#{base_artifact.platform_version}\/", "\/#{map_custom_windows_desktop_versions(dv)}\/")

            base_artifact.clone_with(options)
          end
        end
      end
    end
  end
end
