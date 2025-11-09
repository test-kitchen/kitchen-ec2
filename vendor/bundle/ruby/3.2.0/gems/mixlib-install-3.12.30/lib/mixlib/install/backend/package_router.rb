#
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

require "json" unless defined?(JSON)
require_relative "../artifact_info"
require_relative "base"
require_relative "../product"
require_relative "../product_matrix"
require_relative "../util"
require_relative "../dist"
require "mixlib/versioning"
require "net/http" unless defined?(Net::HTTP)

module Mixlib
  class Install
    class Backend
      class PackageRouter < Base

        COMPAT_DOWNLOAD_URL_ENDPOINT = "http://packages.chef.io".freeze

        # Create filtered list of artifacts
        #
        # @return [Array<ArtifactInfo>] list of artifacts for the configured
        # channel, product name, and product version.
        def available_artifacts
          artifacts = if options.latest_version? || options.partial_version?
                        latest_version
                      else
                        artifacts_for_version(options.product_version)
                      end
          windows_artifact_fixup!(artifacts)
        end

        #
        # Gets available versions from Artifactory via AQL. Returning
        # simply the list of versions.
        #
        # @return [Array<String>] Array of available versions
        def available_versions
          # We are only including a single property, version and that exists
          # under the properties in the following structure:
          # "properties" => [ {"key"=>"omnibus.version", "value"=>"12.13.3"} ]
          ver_list = versions.map { |i| Mixlib::Versioning.parse(extract_version_from_response(i)) }.sort
          ver_list.uniq.map(&:to_s)
        end

        #
        # Get available versions from Artifactory via AQL. Returning the full API response
        #
        # @return [Array<Array<Hash>] Build records for available versions
        def versions
          items = get("/api/v1/#{options.channel}/#{omnibus_project}/versions")["results"]

          # Circumvent early when there are no product artifacts in a specific channel
          if items.empty?
            raise ArtifactsNotFound, <<-EOF
No artifacts found matching criteria.
  product name: #{options.product_name}
  channel: #{options.channel}
EOF
          end

          # Filter out the partial builds if we are in :unstable channel
          # In other channels we do not need to do this since all builds are
          # always complete. In fact we should not do this since for some arcane
          # builds like Chef Client 10.X we do not have build record created in
          # artifactory.
          if options.channel == :unstable
            # We check if "artifacts" field contains something since it is only
            # populated with the build record if "artifact.module.build" exists.
            items.reject! { |i| i["artifacts"].nil? }
          end

          items
        end

        #
        # Get artifacts for the latest version, channel and product_name
        # When a partial version is set the results will be filtered
        # before return latest version.
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        def latest_version
          product_versions = if options.partial_version?
                               v = options.product_version
                               partial_version = v.end_with?(".") ? v : v + "."
                               versions.find_all { |ver| extract_version_from_response(ver).start_with?(partial_version) }
                             else
                               versions
                             end

          # Use mixlib versioning to parse and sort versions
          ordered_versions = product_versions.sort_by do |v|
            Mixlib::Versioning.parse(extract_version_from_response(v))
          end.reverse

          version = extract_version_from_response(ordered_versions.first)
          artifacts_for_version(version)
        end

        def extract_version_from_response(response)
          response["properties"].find { |item| item["key"] == "omnibus.version" }["value"]
        end

        #
        # Get artifacts for a given version, channel and product_name
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        def artifacts_for_version(version)
          begin
            results = get("/api/v1/#{options.channel}/#{omnibus_project}/#{version}/artifacts")["results"]
          rescue Net::HTTPServerException => e
            if e.message =~ /404/
              return []
            else
              raise e
            end
          end

          # Merge artifactory properties to a flat Hash
          results.collect! do |result|
            {
              "filename" => result["name"],
            }.merge(
              map_properties(result["properties"])
            )
          end

          # Convert results to build records
          results.map { |a| create_artifact(a) }
        end

        #
        # GET request
        #
        def get(url)
          uri = URI.parse(endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          full_path = File.join(uri.path, url)
          res = http.request(create_http_request(full_path))
          res.value
          JSON.parse(res.body)
        end

        def create_http_request(full_path)
          request = Net::HTTP::Get.new(full_path)

          request.add_field("User-Agent", Util.user_agent_string(options.user_agent_headers))

          request
        end

        def create_artifact(artifact_map)
          # set normalized platform and platform version
          platform, platform_version = normalize_platform(
            artifact_map["omnibus.platform"],
            artifact_map["omnibus.platform_version"]
          )

          # create the standardized file path
          chef_standard_path = generate_chef_standard_path(
            options.channel,
            artifact_map["omnibus.project"],
            artifact_map["omnibus.version"],
            platform,
            platform_version,
            artifact_map["filename"]
          )

          if options.include_metadata?
            # retrieve the metadata using the standardized path
            begin
              metadata = get("#{chef_standard_path}.metadata.json")
              license_content = metadata["license_content"]
              software_dependencies = metadata.fetch("version_manifest", {})
                                        .fetch("software", nil)
            rescue Net::HTTPServerException => e
              if e.message =~ /404/
                license_content, software_dependencies = nil
              else
                raise e
              end
            end
          else
            license_content, software_dependencies = nil
          end

          # create the download path with the correct endpoint
          base_url = if use_compat_download_url_endpoint?(platform, platform_version)
                       COMPAT_DOWNLOAD_URL_ENDPOINT
                     else
                       endpoint
                     end

          ArtifactInfo.new(
            architecture:          Util.normalize_architecture(artifact_map["omnibus.architecture"]),
            license:               artifact_map["omnibus.license"],
            license_content:       license_content,
            md5:                   artifact_map["omnibus.md5"],
            platform:              platform,
            platform_version:      platform_version,
            product_description:   product_description,
            product_name:          options.product_name,
            sha1:                  artifact_map["omnibus.sha1"],
            sha256:                artifact_map["omnibus.sha256"],
            software_dependencies: software_dependencies,
            url:                   "#{base_url}/#{chef_standard_path}",
            version:               artifact_map["omnibus.version"]
          )
        end

        #
        # For some older platform & platform_version combinations we need to
        # use COMPAT_DOWNLOAD_URL_ENDPOINT since these versions have an
        # OpenSSL version that can not verify the ENDPOINT based urls
        #
        # @return [boolean] use compat download url endpoint
        #
        def use_compat_download_url_endpoint?(platform, platform_version)
          case "#{platform}-#{platform_version}"
          when "freebsd-9", "el-5", "solaris2-5.9", "solaris2-5.10"
            true
          else
            false
          end
        end

        private

        # Converts Array<Hash> where the Hash is a key pair and
        # value pair to a simplified key/pair Hash
        #
        def map_properties(properties)
          return {} if properties.nil?
          properties.each_with_object({}) do |prop, h|
            h[prop["key"]] = prop["value"]
          end
        end

        # Generates a chef standard download uri in the form of
        # /files/:channel/:project/:version/:platform/:platform_version/:file
        def generate_chef_standard_path(channel, project, version, platform, platform_version, filename)
          path = []
          path << "files"
          path << channel
          path << project
          path << version
          path << platform
          path << platform_version
          path << filename
          path.join("/")
        end

        def endpoint
          @endpoint ||= PRODUCT_MATRIX.lookup(options.product_name, options.product_version).api_url
        end

        def omnibus_project
          @omnibus_project ||= PRODUCT_MATRIX.lookup(options.product_name, options.product_version).omnibus_project
        end

        def product_description
          PRODUCT_MATRIX.lookup(options.product_name, options.product_version).product_name
        end
      end
    end
  end
end
