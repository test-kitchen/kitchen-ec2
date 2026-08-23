#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
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

require "fileutils" unless defined?(FileUtils)
require "sshkey" unless defined?(SSHKey)
require "benchmark" unless defined?(Benchmark)
require "json" unless defined?(JSON)
require "kitchen"
require_relative "ec2_version"
require_relative "aws/client"
require_relative "aws/dedicated_hosts"
require_relative "aws/instance_generator"
require_relative "aws/standard_platform"
require_relative "aws/standard_platform/alma"
require_relative "aws/standard_platform/amazon"
require_relative "aws/standard_platform/amazon2"
require_relative "aws/standard_platform/amazon2023"
require_relative "aws/standard_platform/centos"
require_relative "aws/standard_platform/debian"
require_relative "aws/standard_platform/rhel"
require_relative "aws/standard_platform/rocky"
require_relative "aws/standard_platform/fedora"
require_relative "aws/standard_platform/freebsd"
require_relative "aws/standard_platform/macos"
require_relative "aws/standard_platform/ubuntu"
require_relative "aws/standard_platform/windows"
require_relative "aws/instance_connect"
require_relative "aws/ssm_session_manager"
require "aws-sdk-ec2"
require "aws-sdk-core/waiters/errors"
require "retryable" unless defined?(Retryable)
require "time" unless defined?(Time)
require "etc" unless defined?(Etc)
require "socket" unless defined?(Socket)
require "shellwords" unless defined?(Shellwords)

module Kitchen
  # Namespace for Test Kitchen driver plugins.
  module Driver
    # Amazon EC2 driver for Test Kitchen.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class Ec2 < Kitchen::Driver::Base
      kitchen_driver_api_version 2

      plugin_version Kitchen::Driver::EC2_VERSION

      default_config :region, ENV["AWS_REGION"] || "us-east-1"
      default_config :shared_credentials_profile, ENV.fetch("AWS_PROFILE", nil)
      default_config :availability_zone, nil
      default_config :instance_type, &:default_instance_type
      default_config :ebs_optimized, false
      default_config :delete_on_termination, true
      default_config :security_group_ids, nil
      default_config :security_group_filter, nil
      default_config :security_group_cidr_ip, "0.0.0.0/0"
      default_config :tags, "created-by" => "test-kitchen"
      default_config :user_data do |driver|
        if driver.windows_os?
          driver.default_windows_user_data
        end
      end
      default_config :private_ip_address, nil
      default_config :iam_profile_name,   nil
      default_config :spot_price,         nil
      default_config :block_duration_minutes, nil
      default_config :retryable_tries,    60
      default_config :spot_wait,          60
      default_config :retryable_sleep,    5
      default_config :aws_access_key_id,  nil
      default_config :aws_secret_access_key, nil
      default_config :aws_session_token,  nil
      default_config :aws_ssh_key_id,     ENV.fetch("AWS_SSH_KEY_ID", nil)
      default_config :aws_ssh_key_type,   "rsa"
      default_config :image_id, &:default_ami
      default_config :image_search,       nil
      default_config :username,           nil
      default_config :associate_public_ip, nil
      default_config :associate_ipv6,      nil
      default_config :interface,           nil
      default_config :http_proxy,          ENV["HTTPS_PROXY"] || ENV.fetch("HTTP_PROXY", nil)
      default_config :retry_limit,         3
      default_config :tenancy,             "default"
      default_config :instance_initiated_shutdown_behavior, nil
      default_config :ssl_verify_peer, true
      default_config :skip_cost_warning, false
      default_config :allocate_dedicated_host, false
      default_config :deallocate_dedicated_host, false
      default_config :use_instance_connect, false
      default_config :instance_connect_endpoint_id, nil
      default_config :instance_connect_max_tunnel_duration, 3600
      default_config :use_ssm_session_manager, false
      default_config :ssm_session_manager_document_name, nil

      include Kitchen::Driver::Mixins::DedicatedHosts

      # @param args [Array] passed through to {Kitchen::Driver::Base}
      # @param block [Proc] passed through to {Kitchen::Driver::Base}
      def initialize(*args, &block)
        super
      end

      # Warn that a config key is deprecated but still honored.
      #
      # @param driver [Kitchen::Driver::Ec2] the driver being validated
      # @param old_key [Symbol] the deprecated key
      # @param new_key [String, Symbol] what to use instead
      # @return [void]
      def self.validation_warn(driver, old_key, new_key)
        driver.warn "WARN: The driver[#{driver.class.name}] config key `#{old_key}` " \
          "is deprecated, please use `#{new_key}`"
      end

      # Report that a config key has been removed, and stop.
      #
      # Continuing would silently ignore a setting the user believes is in
      # effect, which for keys like `ebs_volume_size` changes the shape of the
      # instance that gets built.
      #
      # @param driver [Kitchen::Driver::Ec2] the driver being validated
      # @param old_key [Symbol] the removed key
      # @param new_key [String, Symbol] what to use instead
      # @return [void] never returns; terminates the process with `exit!`
      def self.validation_error(driver, old_key, new_key)
        warn "ERROR: The driver[#{driver.class.name}] config key `#{old_key}` " \
          "has been removed, please use `#{new_key}`"
        exit!
      end

      # TODO: remove these in 1.1
      deprecated_configs = %i{ebs_volume_size ebs_delete_on_termination ebs_device_name}
      deprecated_configs.each do |d|
        validations[d] = lambda do |attr, val, driver|
          unless val.nil?
            validation_error(driver, attr, "block_device_mappings")
          end
        end
      end
      validations[:ssh_key] = lambda do |attr, val, driver|
        unless val.nil?
          validation_error(driver, attr, "transport.ssh_key")
        end
      end
      validations[:ssh_timeout] = lambda do |attr, val, driver|
        unless val.nil?
          validation_error(driver, attr, "transport.connection_timeout")
        end
      end
      validations[:ssh_retries] = lambda do |attr, val, driver|
        unless val.nil?
          validation_error(driver, attr, "transport.connection_retries")
        end
      end
      validations[:username] = lambda do |attr, val, driver|
        unless val.nil?
          validation_error(driver, attr, "transport.username")
        end
      end
      validations[:flavor_id] = lambda do |attr, val, driver|
        unless val.nil?
          validation_error(driver, attr, "instance_type")
        end
      end

      # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/dedicated-instance.html
      validations[:tenancy] = lambda do |attr, val, _driver|
        unless %w{default host dedicated}.include?(val)
          warn "'#{val}' is an invalid value for option '#{attr}'. " \
            "Valid values are 'default', 'host', or 'dedicated'."
          exit!
        end
      end

      # The access key/secret are now using the priority list AWS uses
      # Providing these inside the .kitchen.yml is no longer recommended
      validations[:aws_access_key_id] = lambda do |attr, val, _driver|
        unless val.nil?
          warn "#{attr} is no longer a valid config option, please use " \
            "ENV['AWS_ACCESS_KEY_ID'] or ~/.aws/credentials. See " \
            "the README for more details"
          exit!
        end
      end
      validations[:aws_secret_access_key] = lambda do |attr, val, _driver|
        unless val.nil?
          warn "#{attr} is no longer a valid config option, please use " \
            "ENV['AWS_SECRET_ACCESS_KEY'] or ~/.aws/credentials. See " \
            "the README for more details"
          exit!
        end
      end
      validations[:aws_session_token] = lambda do |attr, val, _driver|
        unless val.nil?
          warn "#{attr} is no longer a valid config option, please use " \
            "ENV['AWS_SESSION_TOKEN'] or ~/.aws/credentials. See " \
            "the README for more details"
          exit!
        end
      end
      validations[:instance_initiated_shutdown_behavior] = lambda do |attr, val, _driver|
        unless [nil, "stop", "terminate"].include?(val)
          warn "'#{val}' is an invalid value for option '#{attr}'. " \
            "Valid values are 'stop' or 'terminate'"
          exit!
        end
      end

      # Ensure use_instance_connect and use_ssm_session_manager are not both enabled
      validations[:use_ssm_session_manager] = lambda do |_attr, val, driver|
        if val && driver[:use_instance_connect]
          warn "Cannot use both 'use_instance_connect' and 'use_ssm_session_manager' at the same time. " \
            "Please enable only one transport method."
          exit!
        end
      end

      # empty keys cause failures when tagging and they make no sense
      validations[:tags] = lambda do |_attr, val, _driver|
        # if someone puts the tags each on their own line it's an array not a hash
        # @todo we should probably just do the right thing and support this format
        if val.instance_of?(Array)
          warn "AWS instance tags must be specified as a single hash, not a tag " \
            "on each line. Example: {:foo => 'bar', :bar => 'foo'}"
          exit!
        end
      end

      # Create an EC2 instance and wait until it can be connected to.
      #
      # Auto-creates a security group and key pair when none were configured,
      # allocates a dedicated host if `tenancy: host` requires one, requests
      # either an on-demand or a spot instance, then waits for the instance to
      # exist, become ready, and accept a transport connection.
      #
      # Any failure destroys the instance and everything auto-created alongside
      # it, so that a failed create does not leave billable resources behind.
      # Interrupts are re-raised untouched once that cleanup has run.
      #
      # @param state [Hash] the instance state, updated in place with
      #   `:server_id`, `:hostname` and any auto-created credentials
      # @return [void]
      # @raise [Kitchen::ActionFailed] wrapping whatever went wrong, after
      #   cleaning up
      def create(state)
        return if state[:server_id]

        update_username(state)

        info(Kitchen::Util.outdent!(<<-END)) unless config[:skip_cost_warning]
          If you are not using an account that qualifies under the AWS
          free-tier, you may be charged to run these suites. The charge
          should be minimal, but neither Test Kitchen nor its maintainers
          are responsible for your incurred costs.
        END

        # If no security group IDs are specified, create one automatically.
        unless config[:security_group_ids] || config[:security_group_filter]
          create_security_group(state)
          config[:security_group_ids] = [state[:auto_security_group_id]]
        end

        # If no SSH key pair name is specified, create one automatically.
        # If `_disabled`, nullify the key ID to avoid associating the instance with
        # an AWS-managed key pair.
        case config[:aws_ssh_key_id]
        when nil
          create_key(state)
          # Don't set aws_ssh_key_id if using Instance Connect
          config[:aws_ssh_key_id] = state[:auto_key_id] unless config[:use_instance_connect]
        when "_disable"
          info("Disabling AWS-managed SSH key pairs for this EC2 instance.")
          info("The key pairs for the kitchen transport config and the AMI must match.")
          config[:aws_ssh_key_id] = nil
        end

        # Allocate new dedicated hosts if needed and allowed
        if config[:tenancy] == "host"
          unless host_available? || allow_allocate_host?
            warn "ERROR: tenancy `host` requested but no suitable host and allocation not allowed (set `allocate_dedicated_host` setting)"
            exit!
          end

          allocate_host unless host_available?

          info("Auto placement on one dedicated host out of: #{hosts_with_capacity.map(&:host_id).join(", ")}")
        end

        server = if config[:spot_price]
                   # Spot instance when a price is set
                   with_request_limit_backoff(state) { submit_spots }
                 else
                   # On-demand instance
                   with_request_limit_backoff(state) { submit_server }
                 end
        info("Instance <#{server.id}> requested.")
        with_request_limit_backoff(state) do
          logging_proc = ->(attempts) { info("Polling AWS for existence, attempt #{attempts}...") }
          server.wait_until_exists(before_attempt: logging_proc)
        end

        state[:server_id] = server.id
        info("EC2 instance <#{state[:server_id]}> created.")

        # See https://github.com/aws/aws-sdk-ruby/issues/859
        # Waiting can fail, so we have to retry on that.
        Retryable.retryable(
          tries: 10,
          sleep: ->(n) { [2**n, 30].min },
          on: ::Aws::EC2::Errors::InvalidInstanceIDNotFound
        ) do |_r, _|
          wait_until_ready(server, state)
        end

        info("EC2 instance <#{state[:server_id]}> ready (hostname: #{state[:hostname]}).")

        if config[:use_instance_connect]
          instance_connect_setup_ready(state)
        elsif config[:use_ssm_session_manager]
          ssm_session_manager_setup_ready(state)
        end

        instance.transport.connection(state).wait_until_ready
        attach_network_interface(state) unless config[:elastic_network_interface_id].nil?
        create_ec2_json(state) if /chef/i.match?(instance.provisioner.name)
        debug("ec2:create '#{state[:hostname]}'")
      rescue ::Exception => e
        # Deliberately ::Exception, and deliberately broad: a create that is
        # interrupted partway through must still clean up, or the user is left
        # paying for an instance Test Kitchen has forgotten about.
        #
        # Root-qualified because this file is nested inside `module Kitchen`.
        # There is no Kitchen::Exception today, but Kitchen::StandardError does
        # exist, and an unqualified constant would silently pick it up if one
        # were ever added.
        destroy(state)

        # Signals and exits are re-raised untouched. Wrapping a Ctrl-C in an
        # ActionFailed would report the user's own interrupt as a driver bug.
        raise if e.is_a?(::SignalException) || e.is_a?(::SystemExit)

        raise Kitchen::ActionFailed, create_failure_message(e), e.backtrace
      end

      # Describe a failed create without discarding what actually went wrong.
      #
      # This message used to append "in the specified region <region>. Please
      # check this AMI is available in this region" to *every* failure, and to
      # raise a bare RuntimeError, so the original exception class and
      # backtrace were lost. A local OpenSSL fault, an expired credential or a
      # missing subnet all arrived looking like an AMI problem, sending users
      # to check something that was never wrong.
      #
      # The hint is worth keeping -- an AMI that does not exist in the region
      # really is a common mistake -- but only when the failure is about the
      # image.
      #
      # @param error [Exception] the underlying failure
      # @return [String]
      # @see https://github.com/test-kitchen/kitchen-ec2/issues/606
      def create_failure_message(error)
        message = "Failed to create the EC2 instance: #{error.class}: #{error.message}"
        return message unless image_related_error?(error)

        "#{message} Check that image #{config[:image_id]} exists and is available " \
          "in region #{config[:region]}."
      end

      # Whether a failure is about the AMI rather than something else entirely.
      #
      # EC2 reports every image problem with a code beginning "InvalidAMI"; the
      # message check catches errors raised by the driver itself, which are
      # plain strings with no code attached.
      #
      # @param error [Exception] the underlying failure
      # @return [Boolean]
      def image_related_error?(error)
        return true if error.respond_to?(:code) && error.code.to_s.start_with?("InvalidAMI")

        error.message.to_s.match?(/\bAMI\b/i)
      end

      # Terminate the instance and clean up everything created alongside it.
      #
      # An instance that no longer exists is treated as success, since `kitchen
      # destroy` is also how a failed create is cleaned up. Termination is
      # waited on only when an auto-created security group needs removing, as
      # the group cannot be deleted while an instance still references it.
      #
      # @param state [Hash] the instance state, cleaned up in place
      # @return [void]
      def destroy(state)
        if state[:server_id]
          server = ec2.get_instance(state[:server_id])
          unless server.nil?
            instance.transport.connection(state).close
            begin
              server.terminate
            rescue ::Aws::EC2::Errors::InvalidInstanceIDNotFound => e
              warn("Received #{e}, instance was probably already destroyed. Ignoring")
            end
          end
          # If we are going to clean up an automatic security group, we need
          # to wait for the instance to shut down. This slightly breaks the
          # subsystem encapsulation, sorry not sorry.
          if state[:auto_security_group_id] && server && ec2.instance_exists?(state[:server_id])
            wait_log = proc do |attempts|
              c = attempts * config[:retryable_sleep]
              t = config[:retryable_tries] * config[:retryable_sleep]
              info "Waited #{c}/#{t}s for instance <#{server.id}> to terminate."
            end
            server.wait_until_terminated(
              max_attempts: config[:retryable_tries],
              delay: config[:retryable_sleep],
              before_attempt: wait_log
            )
          end
          info("EC2 instance <#{state[:server_id]}> destroyed.")
          state.delete(:server_id)
          state.delete(:hostname)
        end

        # Clean up any auto-created security groups or keys.
        delete_security_group(state)
        delete_key(state)

        # Clean up dedicated hosts matching instance_type and unused (if allowed)
        return unless config[:tenancy] == "host" && allow_deallocate_host?

        empty_hosts = hosts_with_capacity.select { |host| host_unused?(host) }
        empty_hosts.each { |host| deallocate_host(host.host_id) }
      end

      # The EC2 image this instance will be created from.
      #
      # @return [Aws::EC2::Image]
      # @raise [RuntimeError] when neither `image_id` nor `image_search` yielded
      #   an image, which happens when the platform name is not recognized and
      #   no explicit search was configured
      def image
        return @image if defined?(@image)

        if config[:image_id]
          @image = ec2.resource.image(config[:image_id])
          show_chosen_image

        else
          raise "Neither image_id nor an image_search specified for instance #{instance.name}!" \
                " Please specify one or the other."
        end

        @image
      end

      # The instance type to use when the user did not choose one.
      #
      # t3 instances require a hardware-virtualized image, so a paravirtual
      # image falls back to the older t1 family.
      #
      # @return [String] a free-tier instance type
      def default_instance_type
        @instance_type ||= if image && image.virtualization_type == "hvm"
                             info("instance_type not specified. Using free tier t3.micro instance ...")
                             "t3.micro"
                           else
                             info("instance_type not specified. Using free tier t1.micro instance since" \
                                  " image is paravirtual (pick an hvm image to use the superior t3.micro!) ...")
                             "t1.micro"
                           end
      end

      # The platform detected from the image actually being used.
      #
      # This can differ from {#desired_platform}: the user asks for "ubuntu" and
      # gets whichever Ubuntu release the search matched. It is the source of
      # the default SSH username.
      #
      # @return [Kitchen::Driver::Aws::StandardPlatform, nil] nil when no
      #   platform recognizes the image
      def actual_platform
        @actual_platform ||= Aws::StandardPlatform.from_image(self, image) if image
      end

      # The platform requested by the Test Kitchen platform name.
      #
      # @return [Kitchen::Driver::Aws::StandardPlatform, nil] nil when the
      #   platform name is not one the driver knows how to search for
      def desired_platform
        @desired_platform ||= begin
          platform = Aws::StandardPlatform.from_platform_string(self, instance.platform.name)
          if platform
            debug("platform name #{instance.platform.name} appears to be a standard platform." \
                  " Searching for #{platform} ...")
          end
          platform
        end
      end

      # Search for an image matching the requested platform.
      #
      # Falls back to searching for Ubuntu when the platform name is not
      # recognized, so that `kitchen create` still does something useful.
      #
      # @return [String, nil] the image ID, or nil when the search matched nothing
      def default_ami
        @default_ami ||= begin
          search_platform = desired_platform ||
            Aws::StandardPlatform.from_platform_string(self, "ubuntu")
          image_search = config[:image_search] || search_platform.image_search
          search_platform.find_image(image_search)
        end
      end

      # Record the platform's default SSH username in the instance state.
      #
      # Only applied when the transport is still using its own default username,
      # so that a username the user configured is never overwritten.
      #
      # @param state [Hash] the instance state, updated in place
      # @return [void]
      def update_username(state)
        # BUG: With the following equality condition on username, if the user specifies 'root'
        # as the transport's username then we will overwrite that value with one from the standard
        # platform definitions. This seems difficult to handle here as the default username is
        # provided by the underlying transport classes, and is often non-nil (eg; 'root'), leaving
        # us no way to distinguish a user-set value from the transport's default.
        # See https://github.com/test-kitchen/kitchen-ec2/pull/273
        if actual_platform &&
            instance.transport[:username] == instance.transport.class.defaults[:username]
          debug("No SSH username specified: using default username #{actual_platform.username} " \
                "for image #{config[:image_id]}, which we detected as #{actual_platform}.")
          state[:username] = actual_platform.username
        end
      end

      # The EC2 client wrapper, configured from the driver config.
      #
      # @return [Kitchen::Driver::Aws::Client]
      def ec2
        @ec2 ||= Aws::Client.new(
          config[:region],
          config[:shared_credentials_profile],
          config[:http_proxy],
          config[:retry_limit],
          config[:ssl_verify_peer]
        )
      end

      # A generator for the RunInstances payload.
      #
      # @note Deliberately reassigned rather than memoized with `||=`: spot
      #   requests retry against a rewritten {#config}, and a cached generator
      #   would keep building the payload from the config of the first attempt.
      #
      # @return [Kitchen::Driver::Aws::InstanceGenerator]
      def instance_generator
        @instance_generator = Aws::InstanceGenerator.new(config, ec2, instance.logger)
      end

      # Request a single on-demand instance.
      #
      # @return [Aws::EC2::Instance] the newly requested instance
      def submit_server
        instance_data = instance_generator.ec2_instance_data
        debug("Creating EC2 instance in region #{config[:region]} with properties:")
        instance_data.each do |key, value|
          debug("- #{key} = #{value.inspect}")
        end

        ec2.create_instance(instance_data)
      end

      # The driver config.
      #
      # {#submit_spots} overrides this with a rewritten config while trying each
      # instance type and subnet combination, so the generator and the rest of
      # the driver see the variant currently being attempted.
      #
      # @return [Hash] the config in effect
      def config
        return super unless @config

        @config
      end

      # Expand a config whose value for `key` is a list into one config per
      # element.
      #
      # Used to turn `instance_type: [a, b]` into two candidate configs to try
      # in turn. The original config is cloned rather than mutated.
      #
      # @param conf [Hash] the config to expand
      # @param key [Symbol] the key that may hold a list
      # @return [Array<Hash>] one config per value, or `[conf]` when the value
      #   is not a list
      def expand_config(conf, key)
        configs = []

        if conf[key].is_a?(Array)
          values = conf[key]
          values.each do |value|
            new_config = conf.clone
            new_config[key] = value
            configs.push new_config
          end
        else
          configs.push conf
        end

        configs
      end

      # Request a spot instance, trying each viable configuration in turn.
      #
      # Spot capacity is per instance type and per availability zone, so a
      # request can fail for reasons that a different type or subnet would
      # satisfy. Every combination of instance type and subnet is attempted
      # before giving up, and all the failures are reported together.
      #
      # @return [Aws::EC2::Instance] the first instance that could be fulfilled
      # @raise [RuntimeError] listing every failure when none could be fulfilled
      def submit_spots
        configs = [config]
        expanded = []
        keys = %i{instance_type}

        if config[:subnet_filter]
          # => Enable cascading through matching subnets
          client = ::Aws::EC2::Client.new(region: config[:region])

          filters = [config[:subnet_filter]].flatten

          r = { filters: [] }
          filters.each do |subnet_filter|
            r[:filters] <<
              {
                name: "tag:#{subnet_filter[:tag]}",
                values: [subnet_filter[:value]],
              }
          end

          subnets = client.describe_subnets(r).subnets

          raise "Subnets with tags '#{filters}' not found!" if subnets.empty?

          configs = subnets.map do |subnet|
            new_config = config.clone
            new_config[:subnet_id] = subnet.subnet_id
            new_config[:subnet_filter] = nil
            new_config
          end
        else
          # => Use explicitly specified subnets
          keys << :subnet_id
        end

        keys.each do |key|
          configs.each do |conf|
            expanded.push expand_config(conf, key)
          end
          configs = expanded.flatten
          expanded = []
        end

        errs = []
        configs.each do |conf|
          @config = conf
          return submit_spot
        rescue => e
          errs.append(e)
        end
        raise ["Could not create a spot instance:", errs].flatten.join("\n")
      end

      # Request a single spot instance for the current config.
      #
      # A `spot_price` of "ondemand" or "on-demand" requests a spot instance
      # with no price cap, which EC2 expresses by omitting `max_price`.
      #
      # `create_instances` is used rather than `request_spot_instances` because
      # only the former can tag an instance at creation time; the retry loop
      # compensates for its lack of built-in waiting.
      #
      # @return [Aws::EC2::Instance] the newly requested instance
      # @raise [Aws::EC2::Errors::SpotMaxPriceTooLow] when the price could not be
      #   satisfied within `spot_wait` seconds
      def submit_spot
        debug("Creating EC2 Spot Instance..")
        instance_data = instance_generator.ec2_instance_data

        config_spot_price = config[:spot_price].to_s
        spot_price = if %w{ondemand on-demand}.include?(config_spot_price)
                       ""
                     else
                       config_spot_price
                     end
        spot_options = {
          # Must use one-time in order to use instance_interruption_behavior=terminate
          # spot_instance_type: "one-time", # default
          # Must use instance_interruption_behavior=terminate in order to use block_duration_minutes
          # instance_interruption_behavior: "terminate", # default
        }
        if config[:block_duration_minutes]
          spot_options[:block_duration_minutes] = config[:block_duration_minutes]
        end
        unless spot_price == "" # i.e. on-demand
          spot_options[:max_price] = spot_price
        end

        instance_data[:instance_market_options] = {
          market_type: "spot",
          spot_options:,
        }

        # The preferred way to create a spot instance is via request_spot_instances()
        # However, it does not allow for tagging to occur at creation time.
        # create_instances() allows creation of tagged spot instances, but does
        # not retry if the price could not be satisfied immediately.
        Retryable.retryable(
          tries: config[:spot_wait] / config[:retryable_sleep],
          sleep: ->(_n) { config[:retryable_sleep] },
          on: ::Aws::EC2::Errors::SpotMaxPriceTooLow
        ) do |retries|
          c = retries * config[:retryable_sleep]
          t = config[:spot_wait]
          info "Waited #{c}/#{t}s for spot request to become fulfilled."
          ec2.create_instance(instance_data)
        end
      end

      # Wait until an instance is genuinely usable.
      #
      # `server.wait_until_running` is not sufficient: an instance can report
      # running before it has an address, and a Windows instance is not usable
      # until its console output says so. The hostname is stored as soon as it
      # is known so that a later failure still leaves enough state to clean up.
      #
      # @param server [Aws::EC2::Instance] the instance to wait on
      # @param state [Hash] the instance state, updated in place
      # @return [void]
      def wait_until_ready(server, state)
        wait_with_destroy(server, state, "to become ready") do |aws_instance|
          hostname = hostname(aws_instance, config[:interface])
          # We aggressively store the hostname so if the process fails here
          # we still have it, even if it will change later
          state[:hostname] = hostname
          # Euca instances often report ready before they have an IP
          ready = aws_instance.exists? &&
            aws_instance.state.name == "running" &&
            hostname != "0.0.0.0"

          if ready && (hostname.nil? || hostname == "")
            debug("Unable to detect hostname using interface_type #{config[:interface]}. Fallback to ordered mapping")
            state[:hostname] = hostname(aws_instance, nil)
          end
          if ready && windows_os?
            if instance.transport[:username] =~ /administrator/i &&
                instance.transport[:password].nil?
              # If we're logging into the administrator user and a password isn't
              # supplied, try to fetch it from the AWS instance
              fetch_windows_admin_password(server, state)
            else
              output = server.console_output.output || ""
              unless output.nil?
                output = Base64.decode64(output)
                debug "Console output: --- \n#{output}"
              end
              ready = !!output.include?("Windows is Ready to use")
            end
          end
          ready
        end
      end

      # Poll until a block returns true, destroying the instance if it never does.
      #
      # An instance that never becomes ready would otherwise keep running and
      # accruing charges after Test Kitchen gave up on it.
      #
      # @param server [Aws::EC2::Instance] the instance to wait on
      # @param state [Hash] the instance state
      # @param status_msg [String] what is being waited for, for log messages
      # @yieldparam aws_instance [Aws::EC2::Instance] the instance being polled
      # @yieldreturn [Boolean] true when the wait is over
      # @return [void]
      # @raise [Aws::Waiters::Errors::WaiterFailed] after destroying the instance
      def wait_with_destroy(server, state, status_msg, &block)
        wait_log = proc do |attempts|
          c = attempts * config[:retryable_sleep]
          t = config[:retryable_tries] * config[:retryable_sleep]
          info "Waited #{c}/#{t}s for instance <#{state[:server_id]}> #{status_msg}."
        end
        begin
          with_request_limit_backoff(state) do
            server.wait_until(
              max_attempts: config[:retryable_tries],
              delay: config[:retryable_sleep],
              before_attempt: wait_log,
              &block
            )
          end
        rescue ::Aws::Waiters::Errors::WaiterFailed
          error("Ran out of time waiting for the server with id [#{state[:server_id]}]" \
            " #{status_msg}, attempting to destroy it")
          destroy(state)
          raise
        end
      end

      # Wait for and decrypt the generated Windows administrator password.
      #
      # EC2 returns blank password data until the password is available, so this
      # polls first and then decrypts with the instance's private key.
      #
      # @param server [Aws::EC2::Instance] the instance
      # @param state [Hash] the instance state, updated in place with `:password`
      # @return [void]
      def fetch_windows_admin_password(server, state)
        wait_with_destroy(server, state, "to fetch windows admin password") do |_aws_instance|
          enc = server.client.get_password_data(
            instance_id: state[:server_id]
          ).password_data
          # Password data is blank until password is available
          !enc.nil? && !enc.empty?
        end
        pass = with_request_limit_backoff(state) do
          server.decrypt_windows_password(File.expand_path(state[:ssh_key] || instance.transport[:ssh_key]))
        end
        state[:password] = pass
        info("Retrieved Windows password for instance <#{state[:server_id]}>.")
      end

      # Retry a block with quadratic backoff when EC2 throttles the request.
      #
      # Only throttling is retried; any other error is re-raised immediately so
      # that a genuine failure is not delayed by five pointless retries.
      #
      # @param state [Hash] the instance state, used for log messages
      # @yieldreturn [Object] the block's value
      # @return [Object] the block's value
      def with_request_limit_backoff(state)
        retries = 0
        begin
          yield
        rescue ::Aws::EC2::Errors::RequestLimitExceeded, ::Aws::Waiters::Errors::UnexpectedError => e
          raise unless retries < 5 && e.message.include?("Request limit exceeded")

          retries += 1
          info("Request limit exceeded for instance <#{state[:server_id]}>." \
               " Trying again in #{retries**2} seconds.")
          sleep(retries**2)
          retry
        end
      end

      # Mapping from the `interface` config value to the EC2 instance attribute
      # holding that address, in the order they are preferred when no interface
      # was requested.
      #
      # @return [Hash{String => String}]
      INTERFACE_TYPES =
        {
          "dns" => "public_dns_name",
          "public" => "public_ip_address",
          "private" => "private_ip_address",
          "private_dns" => "private_dns_name",
          "id" => "id",
        }.freeze

      #
      # Lookup hostname of provided server. If interface_type is provided use
      # that interface to lookup hostname. Otherwise, try ordered list of
      # options.
      #
      # The address to connect to an instance on.
      #
      # With no interface type, {INTERFACE_TYPES} is walked in order and the
      # first populated value wins. AWS returns an empty string rather than nil
      # for an address that is not assigned yet, so empty values are skipped.
      #
      # @param server [Aws::EC2::Instance] the instance
      # @param interface_type [String, nil] one of the keys of {INTERFACE_TYPES}
      # @return [String, nil] the address, or nil when none is available yet
      # @raise [Kitchen::UserError] when `interface_type` is not recognized
      def hostname(server, interface_type = nil)
        if interface_type
          interface_type = INTERFACE_TYPES.fetch(interface_type) do
            raise Kitchen::UserError, "Invalid interface [#{interface_type}]"
          end
          server.send(interface_type)
        else
          potential_hostname = nil
          INTERFACE_TYPES.each_value do |type|
            potential_hostname ||= server.send(type)
            # AWS returns an empty string if the dns name isn't populated yet
            potential_hostname = nil if potential_hostname == ""
          end
          potential_hostname
        end
      end

      #
      # Returns the sudo command to use or empty string if sudo is not configured
      #
      # The command used to elevate privileges, if any.
      #
      # @return [String] the sudo command, or an empty string when sudo is off
      def sudo_command
        instance.provisioner[:sudo] ? instance.provisioner[:sudo_command].to_s : ""
      end

      # Write the Ohai EC2 hint file on the instance.
      #
      # Chef's `ec2` Ohai plugin only collects EC2 metadata when this hint file
      # is present, so it is created for Chef provisioners.
      #
      # @param state [Hash] the instance state
      # @return [void]
      def create_ec2_json(state)
        if windows_os?
          cmd = 'New-Item -Force C:\\chef\\ohai\\hints\\ec2.json -ItemType File'
        else
          debug "Using sudo_command='#{sudo_command}' for ohai hints"
          cmd = "#{sudo_command} mkdir -p /etc/chef/ohai/hints; #{sudo_command} touch /etc/chef/ohai/hints/ec2.json"
        end
        instance.transport.connection(state).execute(cmd)
      end

      # The default PowerShell user data script for Windows instances.
      #
      # Enables PS remoting, opens the WinRM firewall port and configures WinRM
      # limits, without which a freshly created Windows instance cannot be
      # connected to. Handles both EC2Launch (2016+) and the older EC2Config
      # service, which log to different paths.
      #
      # When the transport uses an account other than Administrator, a matching
      # local account is created and password complexity is relaxed first, since
      # a generated password may not satisfy the default policy.
      #
      # @return [String] a PowerShell script wrapped in `<powershell>` tags
      def default_windows_user_data
        base_script = Kitchen::Util.outdent!(<<-EOH)
	$OSVersion = (get-itemproperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" -Name ProductName).ProductName
  If($OSVersion.contains('2016') -Or $OSVersion.contains('2019') -Or $OSVersion -eq 'Windows Server Datacenter') {
    New-Item -ItemType Directory -Force -Path 'C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log'
    $logfile='C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Log\\kitchen-ec2.log'
    # EC2Launch doesn't init extra disks by default
    C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeDisks.ps1
  } Else {
     New-Item -ItemType Directory -Force -Path 'C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs'
     $logfile='C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs\\kitchen-ec2.log'
  }

        # Logfile fail-safe in case the directory does not exist
        New-Item $logfile -Type file -Force

        # Allow script execution
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        #PS Remoting and & winrm.cmd basic config
        $enableArgs=@{Force=$true}
        $command=Get-Command Enable-PSRemoting
        if($command.Parameters.Keys -contains "skipnetworkprofilecheck"){
            $enableArgs.skipnetworkprofilecheck=$true
        }
        Enable-PSRemoting @enableArgs
        & winrm.cmd set winrm/config '@{MaxTimeoutms="1800000"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxShellsPerUser="50"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' >> $logfile
        #Firewall Config
        & netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any  >> $logfile
        Set-ItemProperty -Name LocalAccountTokenFilterPolicy -Path HKLM:\\software\\Microsoft\\Windows\\CurrentVersion\\Policies\\system -Value 1
        EOH

        # Preparing custom static admin user if we defined something other than Administrator
        custom_admin_script = ""
        if instance.transport[:username] !~ /administrator/i && instance.transport[:password]
          custom_admin_script = Kitchen::Util.outdent!(<<-EOH)
          "Disabling Complex Passwords" >> $logfile
          $seccfg = [IO.Path]::GetTempFileName()
          & secedit.exe /export /cfg $seccfg >> $logfile
          (Get-Content $seccfg) | Foreach-Object {$_ -replace "PasswordComplexity\\s*=\\s*1", "PasswordComplexity = 0"} | Set-Content $seccfg
          & secedit.exe /configure /db $env:windir\\security\\new.sdb /cfg $seccfg /areas SECURITYPOLICY >> $logfile
          & cp $seccfg "c:\\"
          & del $seccfg
          $username="#{instance.transport[:username]}"
          $password="#{instance.transport[:password]}"
          "Creating static user: $username" >> $logfile
          & net.exe user /y /add $username $password >> $logfile
          "Adding $username to Administrators" >> $logfile
          & net.exe localgroup Administrators /add $username >> $logfile
          EOH
        end

        # Returning the fully constructed PowerShell script to user_data
        Kitchen::Util.outdent!(<<-EOH)
        <powershell>
        #{base_script}
        #{custom_admin_script}
        </powershell>
        EOH
      end

      # Log which image was chosen and what platform was detected on it.
      #
      # @return [void]
      def show_chosen_image
        # Print some debug stuff
        debug("Image for #{instance.name}: #{image.name}. #{image_info(image)}")
        if actual_platform
          info("Detected platform: #{actual_platform.name} version #{actual_platform.version}" \
               " on #{actual_platform.architecture}. Instance Type: #{config[:instance_type]}." \
               " Default username: #{actual_platform.username} (default).")
        else
          debug("No platform detected for #{image.name}.")
        end
      end

      # A one-line summary of the attributes that drive image selection.
      #
      # @param image [Aws::EC2::Image] the image to describe
      # @return [String] architecture, virtualization, storage and creation date
      def image_info(image)
        root_device = image.block_device_mappings
          .find { |b| b.device_name == image.root_device_name }
        volume_type = " #{root_device.ebs.volume_type}" if root_device&.ebs

        " Architecture: #{image.architecture}," \
        " Virtualization: #{image.virtualization_type}," \
        " Storage: #{image.root_device_type}#{volume_type}," \
        " Created: #{image.creation_date}"
      end

      # Create a temporary security group for this instance.
      #
      # @api private
      # @param state [Hash] Instance state hash.
      # @return [void]
      def create_security_group(state)
        return if state[:auto_security_group_id]

        # Work out which VPC, if any, we are creating in.
        vpc_id = if config[:subnet_id]
                   # Get the VPC ID for the subnet.
                   subnets = ec2.client.describe_subnets(filters: [{ name: "subnet-id", values: [config[:subnet_id]] }]).subnets
                   raise "Subnet #{config[:subnet_id]} not found during security group creation" if subnets.empty?

                   subnets.first.vpc_id
                 elsif config[:subnet_filter]
                   filters = [config[:subnet_filter]].flatten

                   r = { filters: [] }
                   filters.each do |subnet_filter|
                     r[:filters] << {
                       name: "tag:#{subnet_filter[:tag]}",
                       values: [subnet_filter[:value]],
                     }
                   end

                   subnets = ec2.client.describe_subnets(r).subnets

                   raise "Subnets with tags '#{filters}' not found during security group creation" if subnets.empty?

                   subnets.first.vpc_id
                 else
                   # Try to check for a default VPC.
                   vpcs = ec2.client.describe_vpcs(filters: [{ name: "isDefault", values: ["true"] }]).vpcs
                   if vpcs.empty?
                     # No default VPC so assume EC2-Classic ¯\_(ツ)_/¯
                     nil
                   else
                     # I don't actually know if you can have more than one default VPC?
                     vpcs.first.vpc_id
                   end
                 end
        # Create the SG.
        params = {
          group_name: "kitchen-#{Array.new(8) { rand(36).to_s(36) }.join}",
          description: "Test Kitchen for #{instance.name} by #{Etc.getlogin || "nologin"} on #{Socket.gethostname}",
          tag_specifications: [
            {
              resource_type: "security-group",
              tags: [
                {
                  key: "created-by",
                  value: "test-kitchen",
                },
              ],
            },
          ],
        }
        params[:vpc_id] = vpc_id if vpc_id
        resp = ec2.client.create_security_group(params)
        state[:auto_security_group_id] = resp.group_id
        info("Created automatic security group #{state[:auto_security_group_id]}")
        debug("  in VPC #{vpc_id || "none"}")
        # Set up SG rules.
        ec2.client.authorize_security_group_ingress(
          group_id: state[:auto_security_group_id],
          # Allow SSH and WinRM (both plain and TLS).
          ip_permissions: [22, 3389, 5985, 5986].map do |port|
            {
              ip_protocol: "tcp",
              from_port: port,
              to_port: port,
              ip_ranges: Array(config[:security_group_cidr_ip]).map do |cidr_ip|
                { cidr_ip: }
              end,
            }
          end
        )
      end

      # Create a temporary SSH key pair for this instance.
      #
      # @api private
      # @param state [Hash] Instance state hash.
      # @return [void]
      def create_key(state)
        return if state[:auto_key_id]

        # Encode a bunch of metadata into the name because that's all we can
        # set for a key pair.
        name_parts = [
          instance.name.gsub(/\W/, ""),
          (Etc.getlogin || "nologin").gsub(/\W/, ""),
          Socket.gethostname.gsub(/\W/, "")[0..20],
          Time.now.utc.iso8601,
          Array.new(8) { rand(36).to_s(36) }.join,
        ]
        # In a perfect world this would generate the key locally and use ImportKey
        # instead for better security, but given the use case that is very likely
        # to rapidly exhaust local entropy by creating a lot of keys. So this is
        # probably fine. If you want very high security, probably don't use this
        # feature anyway.
        resp = ec2.client.create_key_pair(
          key_name: "kitchen-#{name_parts.join("-")}",
          key_type: config[:aws_ssh_key_type],
          tag_specifications: [
            {
              resource_type: "key-pair",
              tags: [
                {
                  key: "created-by",
                  value: "test-kitchen",
                },
              ],
            },
          ]
        )
        state[:auto_key_id] = resp.key_name
        info("Created automatic key pair #{state[:auto_key_id]}")
        # Write the key out with safe permissions
        key_path = "#{config[:kitchen_root]}/.kitchen/#{instance.name}.pem"
        File.open(key_path, File::WRONLY | File::CREAT | File::EXCL, 00600) do |f|
          f.write(resp.key_material)
        end
        # Inject the key into the state to be used by the SSH transport, or for
        # the Windows password decrypt above in {#fetch_windows_admin_password}.
        state[:ssh_key] = key_path
      end

      # Attach a pre-existing elastic network interface to the instance.
      #
      # Attached at device index 1, leaving index 0 for the primary interface.
      # An interface that is already attached is left alone, and one that does
      # not exist is reported without failing the run, since the instance itself
      # is already up by this point.
      #
      # @param state [Hash] the instance state
      # @return [void]
      def attach_network_interface(state)
        info("Attaching Network interface <#{config[:elastic_network_interface_id]}> with the instance <#{state[:server_id]}> .")
        client = ::Aws::EC2::Client.new(region: config[:region])
        begin
          check_eni = client.describe_network_interface_attribute({
                                                                    attribute: "attachment",
                                                                    network_interface_id: config[:elastic_network_interface_id],
                                                                  })
          if check_eni.attachment.nil?
            unless state[:server_id].nil?
              client.attach_network_interface({
                                                device_index: 1,
                                                instance_id: state[:server_id],
                                                network_interface_id: config[:elastic_network_interface_id],
                                              })
              info("Attached Network interface <#{config[:elastic_network_interface_id]}> with the instance <#{state[:server_id]}> .")
            end
          else
            puts "ENI #{config[:elastic_network_interface_id]} already attached."
          end
        rescue ::Aws::EC2::Errors::InvalidNetworkInterfaceIDNotFound => e
          warn(e)
        end
      end

      # Clean up a temporary security group for this instance.
      #
      # @api private
      # @param state [Hash] Instance state hash.
      # @return [void]
      def delete_security_group(state)
        return unless state[:auto_security_group_id]

        info("Removing automatic security group #{state[:auto_security_group_id]}")
        ec2.client.delete_security_group(group_id: state[:auto_security_group_id])
        state.delete(:auto_security_group_id)
      end

      # Clean up a temporary SSH key pair for this instance.
      #
      # @api private
      # @param state [Hash] Instance state hash.
      # @return [void]
      def delete_key(state)
        return unless state[:auto_key_id]

        info("Removing automatic key pair #{state[:auto_key_id]}")
        ec2.client.delete_key_pair(key_name: state[:auto_key_id])
        state.delete(:auto_key_id)
        # The file is not always still there: it may have been cleaned up by
        # hand, wiped along with .kitchen, or never written at all, since
        # create records the key pair in the state before writing it. This is
        # the last thing destroy does, so raising here fails the whole action
        # after every AWS resource has already been cleaned up successfully.
        FileUtils.rm_f("#{config[:kitchen_root]}/.kitchen/#{instance.name}.pem")
      end

      # Finalize the driver config and install transport overrides.
      #
      # Instance Connect and SSM Session Manager both work by wrapping the
      # transport's connection handling, which has to happen before the
      # transport is first used.
      #
      # @param instance [Kitchen::Instance] the instance this driver serves
      # @return [self]
      def finalize_config!(instance)
        super

        # Set up Instance Connect transport override if configured
        if config[:use_instance_connect]
          debug("[AWS EC2 Instance Connect] Setting up Instance Connect overrides")
          instance_connect_setup_override(instance)
          instance_connect_setup_inspec_override(instance)
        elsif config[:use_ssm_session_manager]
          debug("[AWS SSM Session Manager] Setting up SSM Session Manager overrides")
          ssm_session_manager_setup_override(instance)
          ssm_session_manager_setup_inspec_override(instance)
        end

        self
      end

      private

      # Wrap the transport's `connection` method with Instance Connect setup.
      #
      # A pushed Instance Connect key expires after about a minute, so the key
      # is refreshed and the connection mode re-decided before every connection
      # rather than once at create time.
      #
      # Guarded against being applied twice: the override wraps the previous
      # method, so applying it again would wrap the wrapper and push the key
      # more than once per connection.
      #
      # @param instance [Kitchen::Instance] the instance whose transport to wrap
      # @return [void]
      def instance_connect_setup_override(instance)
        # Prevent double pushing of the SSH public keys
        return if instance.transport.respond_to?(:instance_connect_override_applied)

        # Store reference to driver for use in override
        driver_instance = self
        use_instance_connect = config[:use_instance_connect]

        # Override the transport's connection method to inject Instance Connect setup
        original_connection = instance.transport.method(:connection)

        instance.transport.define_singleton_method(:connection) do |state, &block|
          # Set up Instance Connect configuration before every connection
          if use_instance_connect
            # Refresh Instance Connect SSH key
            driver_instance.send(:instance_connect_refresh_key, state)

            # Configure connection mode based on endpoint availability
            if driver_instance.send(:instance_connect_endpoint_available?, state)
              # Proxy command mode - ensure ssh_proxy_command is set
              unless state[:ssh_proxy_command]
                driver_instance.send(:instance_connect_configure_ssh_proxy_command, state)
              end
              driver_instance.debug("[AWS EC2 Instance Connect] Transport using proxy command mode")
            else
              # Direct SSH mode - ensure hostname is set to public DNS
              driver_instance.send(:instance_connect_configure_direct_ssh, state)
              driver_instance.debug("[AWS EC2 Instance Connect] Transport using direct SSH mode")
            end
          end
          # Call original connection method
          original_connection.call(state, &block)
        end

        # Mark as applied to prevent double pushing of the SSH public keys
        instance.transport.define_singleton_method(:instance_connect_override_applied) { true }
      end

      # Wrap the InSpec verifier's `call` method with Instance Connect setup.
      #
      # InSpec builds its own SSH options rather than going through the Test
      # Kitchen transport, so it needs the proxy command or public DNS injected
      # separately from {#instance_connect_setup_override}.
      #
      # @param instance [Kitchen::Instance] the instance whose verifier to wrap
      # @return [void] a no-op unless the verifier is InSpec
      def instance_connect_setup_inspec_override(instance)
        # Only apply to InSpec verifier
        return unless instance.verifier.name.downcase == "inspec"
        return if instance.verifier.respond_to?(:instance_connect_inspec_override_applied)

        # Store reference to driver for use in override
        driver_instance = self
        use_instance_connect = config[:use_instance_connect]

        # Override the verifier's call method to inject proxy command setup
        original_call = instance.verifier.method(:call)

        instance.verifier.define_singleton_method(:call) do |state|
          driver_instance.debug("[AWS EC2 Instance Connect] InSpec call method intercepted, connecting using kitchen-ec2 driver AWS EC2 Instance Connect")
          driver_instance.debug("[AWS EC2 Instance Connect] Instance ID: #{state[:server_id]}")

          # If using Instance Connect, set up the override just before the call
          if use_instance_connect && state[:server_id]

            # Check if we already have the override method defined
            unless respond_to?(:instance_connect_original_runner_options_for_ssh)
              # Store the original method
              define_singleton_method(:instance_connect_original_runner_options_for_ssh, method(:runner_options_for_ssh))

              # Override runner_options_for_ssh
              define_singleton_method(:runner_options_for_ssh) do |config_data|
                # Get the original options
                opts = instance_connect_original_runner_options_for_ssh(config_data)

                # Inject Instance Connect configuration if enabled
                if use_instance_connect && config_data[:server_id]
                  # Refresh Instance Connect SSH key
                  driver_instance.send(:instance_connect_refresh_key, config_data)

                  # Check if we should use proxy command or direct SSH
                  if driver_instance.send(:instance_connect_endpoint_available?, config_data)
                    # Build proxy command with the instance ID from state
                    proxy_command = [
                      "aws", "ec2-instance-connect", "open-tunnel",
                      "--instance-id", config_data[:server_id]
                    ]

                    # Add optional parameters
                    if driver_instance.config[:instance_connect_endpoint_id]
                      proxy_command += ["--instance-connect-endpoint-id", driver_instance.config[:instance_connect_endpoint_id]]
                    end
                    if driver_instance.config[:instance_connect_max_tunnel_duration]
                      proxy_command += ["--max-tunnel-duration", driver_instance.config[:instance_connect_max_tunnel_duration].to_s]
                    end
                    if driver_instance.config[:shared_credentials_profile]
                      proxy_command += ["--profile", driver_instance.config[:shared_credentials_profile]]
                    end
                    proxy_command += ["--region", driver_instance.config[:region]]

                    opts["proxy_command"] = proxy_command.join(" ")
                    driver_instance.info("[AWS EC2 Instance Connect] InSpec using proxy command: #{opts["proxy_command"]}")
                  else
                    # Direct SSH mode - ensure we're using the public DNS and proper SSH options
                    server = driver_instance.ec2.get_instance(config_data[:server_id])
                    public_dns = server&.public_dns_name

                    if public_dns && !public_dns.empty?
                      opts["host"] = public_dns
                      opts["ssh_options"] = (opts["ssh_options"] || {}).merge({
                                                                                "IdentitiesOnly" => "yes",
                                                                              })
                      driver_instance.info("[AWS EC2 Instance Connect] InSpec using direct SSH to #{public_dns} with IdentitiesOnly=yes")
                    else
                      driver_instance.warn("[AWS EC2 Instance Connect] No public DNS available for direct SSH mode")
                    end
                  end
                else
                  driver_instance.info("[AWS EC2 Instance Connect] Not configuring Instance Connect - use_instance_connect: #{use_instance_connect}, server_id present: #{!!config_data[:server_id]}")
                end

                opts
              end
            end
          end

          # Call the original method
          original_call.call(state)
        end

        # Mark as applied to prevent double setup
        instance.verifier.define_singleton_method(:instance_connect_inspec_override_applied) { true }
      end

      # Prepare an instance for its first Instance Connect connection.
      #
      # Chooses between tunnelling through an Instance Connect endpoint and
      # connecting directly over public DNS, then pushes the SSH key.
      #
      # @param state [Hash] the instance state, updated in place
      # @return [void]
      def instance_connect_setup_ready(state)
        # Determine whether to use proxy command or direct SSH based on endpoint availability
        if instance_connect_endpoint_available?(state)
          # Configure SSH proxy command if not already done
          instance_connect_configure_ssh_proxy_command(state) unless state[:ssh_proxy_command]
          info("[AWS EC2 Instance Connect] Using tunnel mode - Instance Connect endpoint available")
        else
          # Configure direct SSH with public DNS
          instance_connect_configure_direct_ssh(state)
          info("[AWS EC2 Instance Connect] Using direct SSH mode - no Instance Connect endpoint")
        end

        # Refresh Instance Connect SSH key before connection
        instance_connect_refresh_key(state)
      end

      # Push the SSH public key to the instance again.
      #
      # Instance Connect keys are accepted for roughly sixty seconds, so this
      # runs before each connection. A failure is warned about rather than
      # raised, because the key may still be valid from a previous push.
      #
      # @note Shells out to the AWS CLI rather than using the SDK client in
      #   {Kitchen::Driver::Aws::InstanceConnect}.
      #
      # @param state [Hash] the instance state
      # @return [void] a no-op when no SSH key is known
      def instance_connect_refresh_key(state)
        # Extract public key from the key that was already set up
        key_path = state[:ssh_key] || instance.transport[:ssh_key]
        return unless key_path

        public_key = instance_connect_extract_public_key(key_path)
        return unless public_key

        username = state[:username] || actual_platform&.username

        # Build AWS CLI command to send public key
        cmd = [
          "aws", "ec2-instance-connect", "send-ssh-public-key",
          "--instance-id", state[:server_id],
          "--instance-os-user", username,
          "--ssh-public-key", public_key,
          "--region", config[:region]
        ]

        cmd += ["--profile", config[:shared_credentials_profile]] if config[:shared_credentials_profile]

        # Execute the command with proper shell escaping
        debug("[AWS EC2 Instance Connect] Refreshing SSH public key for #{state[:server_id]}")
        escaped_cmd = cmd.map { |arg| Shellwords.escape(arg) }.join(" ")
        result = `#{escaped_cmd} 2>&1`
        unless $?.success?
          warn("[AWS EC2 Instance Connect] Failed to refresh SSH key: #{result}")
        end
      end

      # Configure SSH to tunnel through an Instance Connect endpoint.
      #
      # Used for instances with no public address: the AWS CLI opens a tunnel
      # that SSH is pointed at as a proxy command.
      #
      # @param state [Hash] the instance state, updated in place with
      #   `:ssh_proxy_command` and `:instance_connect_config`
      # @return [void]
      def instance_connect_configure_ssh_proxy_command(state)
        info("[AWS EC2 Instance Connect] Configuring proxy command mode (tunnel)")

        # Build the AWS CLI command for the tunnel
        proxy_command = [
          "aws", "ec2-instance-connect", "open-tunnel",
          "--instance-id", state[:server_id]
        ]

        # Add optional parameters
        if config[:instance_connect_endpoint_id]
          proxy_command += ["--instance-connect-endpoint-id", config[:instance_connect_endpoint_id]]
        end
        if config[:instance_connect_max_tunnel_duration]
          proxy_command += ["--max-tunnel-duration", config[:instance_connect_max_tunnel_duration].to_s]
        end
        if config[:shared_credentials_profile]
          proxy_command += ["--profile", config[:shared_credentials_profile]]
        end
        proxy_command += ["--region", config[:region]]
        proxy_command_str = proxy_command.join(" ")

        info("Configuring SSH to use Instance Connect tunnel: #{proxy_command_str}")
        state[:ssh_proxy_command] = proxy_command_str

        # Store Instance Connect details for the transport to use
        state[:instance_connect_config] = {
          server_id: state[:server_id],
          username: state[:username] || actual_platform&.username,
          region: config[:region],
          profile: config[:shared_credentials_profile],
          tunnel_mode: true,
        }
      end

      # Whether an Instance Connect endpoint can be used for this instance.
      #
      # A configured endpoint ID is trusted without a lookup. Otherwise the
      # instance's VPC is searched for a completed endpoint. Instance Connect
      # endpoints are not available in every region or to every IAM principal,
      # so a rejected lookup means "no endpoint" rather than an error.
      #
      # @param state [Hash] the instance state
      # @return [Boolean]
      def instance_connect_endpoint_available?(state)
        # If explicitly configured, respect that configuration
        return true if config[:instance_connect_endpoint_id]

        # Check if there are any instance connect endpoints in the VPC
        vpc_id = get_vpc_id_for_instance(state)
        return false unless vpc_id

        begin
          endpoints = ec2.client.describe_instance_connect_endpoints(
            filters: [
              { name: "vpc-id", values: [vpc_id] },
              { name: "state", values: ["create-complete"] },
            ]
          ).instance_connect_endpoints

          !endpoints.empty?
        rescue ::Aws::EC2::Errors::InvalidAction, ::Aws::EC2::Errors::UnauthorizedOperation => e
          # Instance Connect endpoints may not be available in this region or account
          debug("[AWS EC2 Instance Connect] Cannot check for endpoints: #{e.message}")
          false
        end
      end

      # The VPC an instance belongs to.
      #
      # @param state [Hash] the instance state
      # @return [String, nil] the VPC ID, or nil when it cannot be determined
      def get_vpc_id_for_instance(state)
        # Get the instance details to find its VPC
        return unless state[:server_id]

        begin
          instance_info = ec2.client.describe_instances(instance_ids: [state[:server_id]]).reservations.first&.instances&.first
          return unless instance_info

          instance_info.vpc_id
        rescue => e
          debug("[AWS EC2 Instance Connect] Error getting VPC ID for instance: #{e.message}")
          nil
        end
      end

      # Configure SSH to connect straight to the instance's public DNS name.
      #
      # Used when no Instance Connect endpoint is available. When the instance
      # has no public DNS name there is nothing to switch to, so the existing
      # hostname is kept and a warning is logged.
      #
      # @param state [Hash] the instance state, updated in place
      # @return [void]
      def instance_connect_configure_direct_ssh(state)
        # For direct SSH, we need to ensure the hostname is the public DNS name
        # and configure SSH options appropriately
        server = ec2.get_instance(state[:server_id])
        public_dns = server.public_dns_name

        if public_dns && !public_dns.empty?
          info("[AWS EC2 Instance Connect] Configuring direct SSH to #{public_dns}")
          state[:hostname] = public_dns

          # Store Instance Connect details for direct SSH mode
          state[:instance_connect_config] = {
            server_id: state[:server_id],
            username: state[:username] || actual_platform&.username,
            region: config[:region],
            profile: config[:shared_credentials_profile],
            direct_ssh: true,
            hostname: public_dns,
          }
        else
          warn("[AWS EC2 Instance Connect] No public DNS available for direct SSH, falling back to existing hostname")
        end
      end

      # The OpenSSH public key matching a private key.
      #
      # Prefers an adjacent `.pub` file, and derives the public half from the
      # private key otherwise -- keys created by {#create_key} are downloaded
      # from EC2 as a bare private key with no `.pub` alongside.
      #
      # @param private_key_path [String] path to the private key
      # @return [String] the public key in OpenSSH format
      # @raise [RuntimeError] when the key cannot be read or parsed
      def instance_connect_extract_public_key(private_key_path)
        public_key_path = "#{private_key_path}.pub"

        if File.exist?(public_key_path)
          return File.read(public_key_path).strip
        end

        begin
          key = SSHKey.new(File.read(private_key_path))
          key.ssh_public_key
        rescue => e
          raise "Unable to extract public key from #{private_key_path}: #{e.message}"
        end
      end

      # SSM Session Manager Support Methods

      # The SSM Session Manager helper.
      #
      # @return [Kitchen::Driver::Aws::SsmSessionManager]
      def ssm_session_manager
        @ssm_session_manager ||= Aws::SsmSessionManager.new(config, instance.logger)
      end

      # Wait for an instance to become reachable over SSM.
      #
      # The SSM agent registers itself some time after the instance boots, so
      # this polls for up to two minutes. A timeout is warned about rather than
      # raised: the usual cause is a missing IAM instance profile, and the
      # connection attempt itself gives a clearer error.
      #
      # @param state [Hash] the instance state
      # @return [void]
      def ssm_session_manager_setup_ready(state)
        info("[AWS SSM Session Manager] Setting up SSM Session Manager connection")

        # Verify session manager plugin is installed
        unless ssm_session_manager.session_manager_plugin_installed?
          warn("[AWS SSM Session Manager] Session Manager plugin not found. Please install it from: " \
               "https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html")
        end

        # Wait for SSM agent to be available
        max_retries = 12
        retry_delay = 10
        retries = 0

        loop do
          if ssm_session_manager.ssm_agent_available?(state[:server_id])
            info("[AWS SSM Session Manager] SSM agent is available on instance #{state[:server_id]}")
            break
          end

          retries += 1
          if retries >= max_retries
            warn("[AWS SSM Session Manager] SSM agent did not become available after #{max_retries * retry_delay} seconds. " \
                 "Ensure the instance has an IAM instance profile with SSM permissions and the SSM agent is running.")
            break
          end

          info("[AWS SSM Session Manager] Waiting for SSM agent to be available (attempt #{retries}/#{max_retries})...")
          sleep retry_delay
        end
      end

      # Wrap the transport's `connection` method with SSM Session Manager setup.
      #
      # SSM connections work by pointing SSH at `aws ssm start-session` as a
      # proxy command, which needs the instance ID and so cannot be built until
      # the instance exists.
      #
      # @param instance [Kitchen::Instance] the instance whose transport to wrap
      # @return [void]
      def ssm_session_manager_setup_override(instance)
        # Prevent double setup
        return if instance.transport.respond_to?(:ssm_session_manager_override_applied)

        # Store reference to driver for use in override
        driver_instance = self
        use_ssm = config[:use_ssm_session_manager]

        # Override the transport's connection method to inject SSM setup
        original_connection = instance.transport.method(:connection)

        instance.transport.define_singleton_method(:connection) do |state, &block|
          if use_ssm && state[:server_id]
            # Build SSM start-session command
            cmd = [
              "aws", "ssm", "start-session",
              "--target", state[:server_id],
              "--region", driver_instance.config[:region]
            ]

            # Tunnelling SSH over SSM needs a session document that forwards a
            # port. Without one, `start-session` opens an interactive shell
            # session instead, which speaks nothing SSH understands: pointed at
            # that as a ProxyCommand, SSH waits for a banner that never comes
            # and the create hangs until it is interrupted. AWS-StartSSHSession
            # is the document AWS publishes for this, and `%p` is substituted by
            # Net::SSH::Proxy::Command with the port being connected on, so a
            # transport using a port other than 22 tunnels to that port.
            if driver_instance.config[:ssm_session_manager_document_name]
              cmd += ["--document-name", driver_instance.config[:ssm_session_manager_document_name]]
            else
              cmd += ["--document-name", "AWS-StartSSHSession", "--parameters", "portNumber=%p"]
            end

            # Add AWS profile if specified
            if driver_instance.config[:shared_credentials_profile]
              cmd += ["--profile", driver_instance.config[:shared_credentials_profile]]
            end

            proxy_command = cmd.join(" ")
            driver_instance.info("[AWS SSM Session Manager] Using proxy command: #{proxy_command}")

            # Set proxy command for SSH transport
            state[:ssh_proxy_command] = proxy_command
          end

          # Call original connection method
          original_connection.call(state, &block)
        end

        # Mark as applied
        instance.transport.define_singleton_method(:ssm_session_manager_override_applied) { true }
      end

      # Wrap the InSpec verifier's `call` method with SSM Session Manager setup.
      #
      # InSpec builds its own SSH options rather than going through the Test
      # Kitchen transport, so the proxy command has to be injected separately
      # from {#ssm_session_manager_setup_override}.
      #
      # @param instance [Kitchen::Instance] the instance whose verifier to wrap
      # @return [void] a no-op unless the verifier is InSpec
      def ssm_session_manager_setup_inspec_override(instance)
        # Only apply to InSpec verifier
        return unless instance.verifier.name.downcase == "inspec"
        return if instance.verifier.respond_to?(:ssm_session_manager_inspec_override_applied)

        # Store reference to driver for use in override
        driver_instance = self
        use_ssm = config[:use_ssm_session_manager]

        # Override the verifier's call method to inject SSM setup
        original_call = instance.verifier.method(:call)

        instance.verifier.define_singleton_method(:call) do |state|
          driver_instance.debug("[AWS SSM Session Manager] InSpec call method intercepted")

          # Set up SSM for InSpec if enabled
          if use_ssm && state[:server_id]
            # Check if we already have the override method defined
            unless respond_to?(:ssm_original_runner_options_for_ssh)
              # Store the original method
              define_singleton_method(:ssm_original_runner_options_for_ssh, method(:runner_options_for_ssh))

              # Override runner_options_for_ssh
              define_singleton_method(:runner_options_for_ssh) do |config_data|
                # Get the original options
                opts = ssm_original_runner_options_for_ssh(config_data)

                # Inject SSM Session Manager configuration if enabled
                if use_ssm && config_data[:server_id]
                  # Build SSM start-session command
                  cmd = [
                    "aws", "ssm", "start-session",
                    "--target", config_data[:server_id],
                    "--region", driver_instance.config[:region]
                  ]

                  # Add document name if specified
                  if driver_instance.config[:ssm_session_manager_document_name]
                    cmd += ["--document-name", driver_instance.config[:ssm_session_manager_document_name]]
                  end

                  # Add AWS profile if specified
                  if driver_instance.config[:shared_credentials_profile]
                    cmd += ["--profile", driver_instance.config[:shared_credentials_profile]]
                  end

                  opts["proxy_command"] = cmd.join(" ")
                  driver_instance.info("[AWS SSM Session Manager] InSpec using proxy command: #{opts["proxy_command"]}")
                end

                opts
              end
            end
          end

          # Call the original method
          original_call.call(state)
        end

        # Mark as applied
        instance.verifier.define_singleton_method(:ssm_session_manager_inspec_override_applied) { true }
      end
    end
  end
end
