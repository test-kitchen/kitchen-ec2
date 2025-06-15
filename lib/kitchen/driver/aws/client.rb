#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright:: 2016-2018, Chef Software, Inc.
# Copyright:: 2015-2018, Fletcher Nichol
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

require "aws-sdk-ec2"
require "aws-sdk-core/credentials"
require "aws-sdk-core/shared_credentials"
require "aws-sdk-core/instance_profile_credentials"

module Kitchen
  module Driver
    class Aws
      # A class for creating and managing the EC2 client connection
      #
      # @author Tyler Ball <tball@chef.io>
      class Client
        def initialize(
          region,
          profile_name = "default",
          http_proxy = nil,
          retry_limit = nil,
          ssl_verify_peer = true
        )
          ::Aws.config.update(
            region:,
            profile: profile_name,
            http_proxy:,
            ssl_verify_peer:
          )
          ::Aws.config.update(retry_limit:) unless retry_limit.nil?
        end

        # create a new AWS EC2 instance
        # @param options [Hash] has of instance options
        # @see https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Resource.html#create_instances-instance_method
        # @return [Aws::EC2::Instance]
        def create_instance(options)
          resource.create_instances(options).first
        end

        # get an instance object given an id
        # @param id [String] aws instance id
        # @return [Aws::EC2::Instance]
        def get_instance(id)
          resource.instance(id)
        end

        # get an instance object given a spot request ID
        # @param request_id [String] aws spot instance id
        # @return [Aws::EC2::Instance]
        def get_instance_from_spot_request(request_id)
          resource.instances(
            filters: [{
              name: "spot-instance-request-id",
              values: [request_id],
            }]
          ).to_a[0]
        end

        # check if instance exists, given an id
        # @param id [String] aws instance id
        # @return boolean
        def instance_exists?(id)
          resource.instance(id).exists?
        end

        def client
          @client ||= ::Aws::EC2::Client.new
        end

        def resource
          @resource ||= ::Aws::EC2::Resource.new
        end
      end
    end
  end
end
