#
# Author:: GitHub Copilot
#
# Copyright:: 2025, GitHub
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "aws-sdk-ssm"
require "open3"

module Kitchen
  module Driver
    class Aws
      # Manages AWS Systems Manager Session Manager connections for Test Kitchen
      class SsmSessionManager
        def initialize(config, logger)
          @config = config
          @logger = logger
          @ssm_client = ::Aws::SSM::Client.new(
            region: config[:region],
            profile: config[:shared_credentials_profile]
          )
        end

        # Check if SSM agent is running on the instance
        def ssm_agent_available?(instance_id)
          @logger.debug("Checking if SSM agent is available on instance #{instance_id}")

          begin
            resp = @ssm_client.describe_instance_information(
              filters: [
                {
                  key: "InstanceIds",
                  values: [instance_id],
                },
              ]
            )

            available = !resp.instance_information_list.empty? &&
              resp.instance_information_list.first.ping_status == "Online"

            if available
              @logger.info("SSM agent is available on instance #{instance_id}")
            else
              @logger.warn("SSM agent is not available on instance #{instance_id}")
            end

            available
          rescue ::Aws::SSM::Errors::ServiceError => e
            @logger.warn("Error checking SSM agent status: #{e.message}")
            false
          end
        end

        # Verify that the AWS CLI session manager plugin is installed
        def session_manager_plugin_installed?
          _output, status = Open3.capture2e("session-manager-plugin", "--version")
          installed = status.success?

          if installed
            @logger.debug("Session Manager plugin is installed")
          else
            @logger.warn("Session Manager plugin is not installed. Install it from: " \
                        "https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html")
          end

          installed
        rescue StandardError => e
          @logger.warn("Error checking for session-manager-plugin: #{e.message}")
          false
        end
      end
    end
  end
end
