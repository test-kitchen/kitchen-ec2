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
    # Namespace for the driver's AWS-facing collaborators: the EC2 client
    # wrapper, the RunInstances payload generator, the platform definitions and
    # the Instance Connect and SSM Session Manager helpers.
    class Aws
      # A class for creating and managing the EC2 client connection
      #
      # @author Tyler Ball <tball@chef.io>
      class Client
        # Configure the AWS SDK for this driver's connection settings.
        #
        # These settings are applied to the SDK's process-wide configuration
        # rather than held on this object, so clients built later pick them up.
        # A nil retry limit is omitted rather than written, so that the SDK's
        # own default survives.
        #
        # @param region [String] the AWS region, e.g. "us-west-2"
        # @param profile_name [String] shared credentials profile to use
        # @param http_proxy [String, nil] proxy URL, if any
        # @param retry_limit [Integer, nil] SDK retry limit, or nil for the default
        # @param ssl_verify_peer [Boolean] whether to verify TLS peers
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
        # @return [Boolean]
        def instance_exists?(id)
          resource.instance(id).exists?
        end

        # The low-level EC2 client, for API calls with no resource equivalent.
        #
        # @return [Aws::EC2::Client]
        def client
          @client ||= ::Aws::EC2::Client.new
        end

        # The EC2 resource interface, for working with instances and images as
        # objects rather than raw API responses.
        #
        # @return [Aws::EC2::Resource]
        def resource
          @resource ||= ::Aws::EC2::Resource.new
        end
      end
    end
  end
end
