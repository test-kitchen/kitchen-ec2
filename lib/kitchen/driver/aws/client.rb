# -*- encoding: utf-8 -*-
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
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "aws-sdk"
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
            :region => region,
            :profile => profile_name,
            :http_proxy => http_proxy,
            :ssl_verify_peer => ssl_verify_peer
          )
          ::Aws.config.update(:retry_limit => retry_limit) unless retry_limit.nil?
        end

        def create_instance(options)
          resource.create_instances(options)[0]
        end

        def get_instance(id)
          resource.instance(id)
        end

        def get_instance_from_spot_request(request_id)
          resource.instances(
            :filters => [{
              :name => "spot-instance-request-id",
              :values => [request_id],
            }]
          ).to_a[0]
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
