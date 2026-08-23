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

require "stringio"

# Builders for the Test Kitchen objects the EC2 driver needs in order to run.
#
# The driver is not usable in isolation: almost everything it does reads from
# `instance.transport`, `instance.platform` or `instance.provisioner`. These
# helpers assemble that graph, and route all log output into a StringIO so the
# suite stays quiet while remaining assertable via {#logged_output}.
module DriverFactory
  # Captured log output for the current example.
  #
  # @return [StringIO]
  def logged_output
    @logged_output ||= StringIO.new
  end

  # A logger writing into {#logged_output} at debug level.
  #
  # Debug level matters: much of the driver's interesting reporting is emitted
  # with `debug`, and specs assert on it.
  #
  # @return [Kitchen::Logger]
  def test_logger
    @test_logger ||= Kitchen::Logger.new(
      stdout: logged_output,
      level: :debug,
      color: nil
    )
  end

  # Build an EC2 driver wired to a fully-formed `Kitchen::Instance`.
  #
  # Use this for behavior that crosses the driver/instance boundary --
  # platform detection, transport overrides, config finalization.
  #
  # @param platform_name [String] the Test Kitchen platform name, e.g. "ubuntu-22.04"
  # @param transport [Kitchen::Transport::Base] transport to attach
  # @param provisioner [Kitchen::Provisioner::Base] provisioner to attach
  # @param verifier [Kitchen::Verifier::Base] verifier to attach
  # @param config [Hash] driver config
  # @return [Kitchen::Driver::Ec2]
  def build_driver_with_instance(
    platform_name: "ubuntu-22.04",
    transport: Kitchen::Transport::Dummy.new,
    provisioner: Kitchen::Provisioner::Dummy.new,
    verifier: Kitchen::Verifier::Dummy.new,
    **config
  )
    driver = Kitchen::Driver::Ec2.new({ region: "us-west-2" }.merge(config))

    Kitchen::Instance.new(
      driver: driver,
      suite: Kitchen::Suite.new(name: "default"),
      platform: Kitchen::Platform.new(name: platform_name),
      provisioner: provisioner,
      transport: transport,
      verifier: verifier,
      logger: test_logger,
      state_file: Kitchen::StateFile.new("/nonexistent", "default-#{platform_name}"),
      lifecycle_hooks: Kitchen::LifecycleHooks.new({}, {})
    )

    driver
  end

  # Build an EC2 driver backed by an instance double.
  #
  # Use this for behavior that only needs a handful of instance attributes.
  # The double is verifying, so a spec cannot stub a `Kitchen::Instance` method
  # that does not exist.
  #
  # @param config [Hash] driver config
  # @param instance_attributes [Hash] attributes to expose on the instance double
  # @return [Kitchen::Driver::Ec2]
  def build_driver(instance_attributes: {}, **config)
    driver = Kitchen::Driver::Ec2.new({ region: "us-west-2" }.merge(config))
    allow(driver).to receive(:instance).and_return(
      build_instance_double(**instance_attributes)
    )
    driver
  end

  # A verifying double standing in for `Kitchen::Instance`.
  #
  # @param attributes [Hash] attribute overrides
  # @return [InstanceDouble<Kitchen::Instance>]
  def build_instance_double(**attributes)
    defaults = {
      logger: test_logger,
      name: "default-ubuntu",
      platform: Kitchen::Platform.new(name: "ubuntu-22.04"),
      provisioner: Kitchen::Provisioner::Dummy.new,
      transport: Kitchen::Transport::Dummy.new,
      verifier: Kitchen::Verifier::Dummy.new,
      to_str: "<default-ubuntu>",
    }

    instance_double(Kitchen::Instance, **defaults.merge(attributes))
  end
end
