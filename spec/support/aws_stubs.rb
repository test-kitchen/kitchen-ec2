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
require "aws-sdk-ec2instanceconnect"
require "aws-sdk-ssm"

# Builders for stubbed AWS SDK clients.
#
# Every client here has `stub_responses` enabled, which means it validates
# request parameters against the real service model and returns canned data
# instead of making a network call. That validation is the point: a spec that
# stubs a response with the wrong shape, or driver code that sends a parameter
# the API does not accept, raises rather than passing.
module AwsStubs
  # Fixed credentials and region, so that no example depends on the developer's
  # AWS environment or on `~/.aws/credentials`.
  STUB_REGION = "us-west-2".freeze
  STUB_CREDENTIALS = { access_key_id: "test-akid", secret_access_key: "test-secret" }.freeze

  # A stubbed EC2 client.
  #
  # Pass operation stubs as keyword arguments, e.g.
  # `stub_ec2_client(describe_subnets: { subnets: [...] })`.
  def stub_ec2_client(**stubs)
    build_stub_client(::Aws::EC2::Client, stubs)
  end

  # A stubbed EC2 Instance Connect client.
  def stub_instance_connect_client(**stubs)
    build_stub_client(::Aws::EC2InstanceConnect::Client, stubs)
  end

  # A stubbed SSM client.
  def stub_ssm_client(**stubs)
    build_stub_client(::Aws::SSM::Client, stubs)
  end

  # A `Kitchen::Driver::Aws::Client` double backed by real stubbed SDK objects.
  #
  # The driver reaches AWS through this wrapper, so specs that exercise driver
  # behavior stub the wrapper while leaving the SDK client underneath genuine.
  def stub_aws_client(client: stub_ec2_client, resource: nil)
    resource ||= ::Aws::EC2::Resource.new(client: client)

    instance_double(
      Kitchen::Driver::Aws::Client,
      client: client,
      resource: resource
    )
  end

  # The requests a stubbed client received, newest last.
  #
  # `api_requests` is populated only when the client was built with
  # `stub_responses: true`, which every client from this module is.
  def requests_for(client, operation)
    client.api_requests.select { |request| request[:operation_name] == operation }
  end

  # The parameters of the single request a stubbed client received for an
  # operation. Fails the example if the operation was not called exactly once.
  def request_params_for(client, operation)
    matching = requests_for(client, operation)
    raise "expected exactly one #{operation} request, got #{matching.size}" unless matching.size == 1

    matching.first[:params]
  end

  private

  def build_stub_client(klass, stubs)
    client = klass.new(
      stub_responses: true,
      region: STUB_REGION,
      credentials: ::Aws::Credentials.new(*STUB_CREDENTIALS.values_at(:access_key_id, :secret_access_key))
    )
    stubs.each { |operation, data| client.stub_responses(operation, data) }
    client
  end
end
