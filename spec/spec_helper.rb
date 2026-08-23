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

# Several of the driver's `default_config` blocks read ENV at class-definition
# time, which happens once when "kitchen/driver/ec2" is first required. Clearing
# these here -- before any spec file requires the driver -- keeps a developer's
# real AWS environment from changing the defaults under test.
#
# This only affects the RSpec process; the parent shell is untouched.
%w{
  AWS_ACCESS_KEY_ID
  AWS_PROFILE
  AWS_REGION
  AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN
  AWS_SSH_KEY_ID
  HTTPS_PROXY
  HTTP_PROXY
}.each { |key| ENV.delete(key) }

require "aws-sdk-ec2"

# The no-op plugins the support helpers assemble instances from. Loading them
# here does not pull in the driver under test, so the ENV scrubbing above still
# happens first.
require "kitchen"
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.syntax = :expect
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = false

  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Report every failed expectation in an example rather than aborting at the
  # first one. Individual examples can opt out with `aggregate_failures: false`.
  config.define_derived_metadata do |metadata|
    metadata[:aggregate_failures] = true unless metadata.key?(:aggregate_failures)
  end

  # Progress for a full run; the documentation format is more useful when a
  # single file is being worked on.
  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.include AwsStubs
  config.include DriverFactory
  config.include ImageFixtures

  # The AWS SDK is configured process-wide, and `Kitchen::Driver::Aws::Client`
  # mutates `Aws.config` as a side effect of being constructed. Snapshot and
  # restore it so that configuration cannot leak between examples.
  config.around do |example|
    saved = ::Aws.config.dup
    begin
      example.run
    ensure
      ::Aws.config.replace(saved)
    end
  end

  # A network kill-switch, not a stubbing strategy: examples inject their own
  # explicitly stubbed clients. This only guarantees that a *missed* stub fails
  # locally instead of reaching the real EC2 API.
  config.before do
    ::Aws.config.update(
      stub_responses: true,
      region: "us-west-2",
      credentials: ::Aws::Credentials.new("test-akid", "test-secret")
    )
  end
end
