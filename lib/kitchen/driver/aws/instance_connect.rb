#
# Author:: Alex Kokkinos
#
# Copyright:: 2025, Alex Kokkinos
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
require "aws-sdk-ec2instanceconnect"

module Kitchen
  module Driver
    class Aws
      # Pushes short-lived SSH public keys to an instance using EC2 Instance
      # Connect, so that a connection can be made without a long-lived key pair.
      #
      # A pushed key is accepted for roughly sixty seconds, so it is sent again
      # before each connection rather than once at create time.
      class InstanceConnect
        # @param config [Hash] the driver config
        # @param logger [Kitchen::Logger] the logger to report through
        def initialize(config, logger)
          @config = config
          @logger = logger
          @client = ::Aws::EC2InstanceConnect::Client.new(region: config[:region])
        end

        # Push an SSH public key to an instance for a given user.
        #
        # @param instance_id [String] the target instance, e.g. "i-0123abcd"
        # @param username [String] the OS account to authorize the key for
        # @param public_key [String] the OpenSSH-format public key
        # @raise [Aws::EC2InstanceConnect::Errors::ServiceError] when the key is
        #   rejected; there is no usable connection in that case, so the error
        #   is not swallowed
        # @return [void]
        def send_ssh_public_key(instance_id, username, public_key)
          @logger.info("Sending SSH public key to instance #{instance_id} for user #{username}")

          @client.send_ssh_public_key({
            instance_id: instance_id,
            instance_os_user: username,
            ssh_public_key: public_key,
            availability_zone: @config[:availability_zone],
          })

          @logger.debug("SSH public key successfully sent to instance")
        end
      end
    end
  end
end
