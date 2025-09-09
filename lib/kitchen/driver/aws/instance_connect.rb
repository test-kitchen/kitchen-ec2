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
      class InstanceConnect
        def initialize(config, logger)
          @config = config
          @logger = logger
          @client = ::Aws::EC2InstanceConnect::Client.new(region: config[:region])
        end

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
