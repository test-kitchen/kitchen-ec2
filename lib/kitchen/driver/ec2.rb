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
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
require "aws-sdk-ec2"
require "aws-sdk-core/waiters/errors"
require "retryable" unless defined?(Retryable)
require "time" unless defined?(Time)
require "etc" unless defined?(Etc)
require "socket" unless defined?(Socket)

module Kitchen

  module Driver

    # Amazon EC2 driver for Test Kitchen.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class Ec2 < Kitchen::Driver::Base

      kitchen_driver_api_version 2

      plugin_version Kitchen::Driver::EC2_VERSION

      default_config :region, ENV["AWS_REGION"] || "us-east-1"
      default_config :shared_credentials_profile, ENV["AWS_PROFILE"]
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
      default_config :aws_ssh_key_id,     ENV["AWS_SSH_KEY_ID"]
      default_config :aws_ssh_key_type,   "rsa"
      default_config :image_id, &:default_ami
      default_config :image_search,       nil
      default_config :username,           nil
      default_config :associate_public_ip, nil
      default_config :interface,           nil
      default_config :http_proxy,          ENV["HTTPS_PROXY"] || ENV["HTTP_PROXY"]
      default_config :retry_limit,         3
      default_config :tenancy,             "default"
      default_config :instance_initiated_shutdown_behavior, nil
      default_config :ssl_verify_peer, true
      default_config :skip_cost_warning, false
      default_config :allocate_dedicated_host, false
      default_config :deallocate_dedicated_host, false

      include Kitchen::Driver::Mixins::DedicatedHosts

      def initialize(*args, &block)
        super
      end

      def self.validation_warn(driver, old_key, new_key)
        driver.warn "WARN: The driver[#{driver.class.name}] config key `#{old_key}` " \
          "is deprecated, please use `#{new_key}`"
      end

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

      # empty keys cause failures when tagging and they make no sense
      validations[:tags] = lambda do |attr, val, _driver|
        # if someone puts the tags each on their own line it's an array not a hash
        # @todo we should probably just do the right thing and support this format
        if val.class == Array
          warn "AWS instance tags must be specified as a single hash, not a tag " \
            "on each line. Example: {:foo => 'bar', :bar => 'foo'}"
          exit!
        end
      end

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
          config[:aws_ssh_key_id] = state[:auto_key_id]
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

        if config[:spot_price]
          # Spot instance when a price is set
          server = with_request_limit_backoff(state) { submit_spots }
        else
          # On-demand instance
          server = with_request_limit_backoff(state) { submit_server }
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
          sleep: lambda { |n| [2**n, 30].min },
          on: ::Aws::EC2::Errors::InvalidInstanceIDNotFound
        ) do |r, _|
          wait_until_ready(server, state)
        end

        info("EC2 instance <#{state[:server_id]}> ready (hostname: #{state[:hostname]}).")
        instance.transport.connection(state).wait_until_ready
        attach_network_interface(state) unless config[:elastic_network_interface_id].nil?
        create_ec2_json(state) if /chef/i.match?(instance.provisioner.name)
        debug("ec2:create '#{state[:hostname]}'")
      rescue Exception => e
        # Clean up the instance and any auto-created security groups or keys on the way out.
        destroy(state)
        raise "#{e.message} in the specified region #{config[:region]}. Please check this AMI is available in this region."
      end

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
        if config[:tenancy] == "host" && allow_deallocate_host?
          empty_hosts = hosts_with_capacity.select { |host| host_unused?(host) }
          empty_hosts.each { |host| deallocate_host(host.host_id) }
        end
      end

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

      def default_instance_type
        @instance_type ||= if image && image.virtualization_type == "hvm"
                             info("instance_type not specified. Using free tier t2.micro instance ...")
                             "t2.micro"
                           else
                             info("instance_type not specified. Using free tier t1.micro instance since" \
                                  " image is paravirtual (pick an hvm image to use the superior t2.micro!) ...")
                             "t1.micro"
                           end
      end

      # The actual platform is the platform detected from the image
      def actual_platform
        @actual_platform ||= Aws::StandardPlatform.from_image(self, image) if image
      end

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

      def default_ami
        @default_ami ||= begin
          search_platform = desired_platform ||
            Aws::StandardPlatform.from_platform_string(self, "ubuntu")
          image_search = config[:image_search] || search_platform.image_search
          search_platform.find_image(image_search)
        end
      end

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

      def ec2
        @ec2 ||= Aws::Client.new(
          config[:region],
          config[:shared_credentials_profile],
          config[:http_proxy],
          config[:retry_limit],
          config[:ssl_verify_peer]
        )
      end

      def instance_generator
        @instance_generator = Aws::InstanceGenerator.new(config, ec2, instance.logger)
      end

      # AWS helper for creating the instance
      def submit_server
        instance_data = instance_generator.ec2_instance_data
        debug("Creating EC2 instance in region #{config[:region]} with properties:")
        instance_data.each do |key, value|
          debug("- #{key} = #{value.inspect}")
        end

        ec2.create_instance(instance_data)
      end

      def config
        return super unless @config

        @config
      end

      # Take one config and expand to multiple configs
      def expand_config(conf, key)
        configs = []

        if conf[key] && conf[key].is_a?(Array)
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

      def submit_spots
        configs = [config]
        expanded = []
        keys = %i{instance_type}

        unless config[:subnet_filter]
          # => Use explicitly specified subnets
          keys << :subnet_id
        else
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

      def submit_spot
        debug("Creating EC2 Spot Instance..")
        instance_data = instance_generator.ec2_instance_data

        config_spot_price = config[:spot_price].to_s
        if %w{ondemand on-demand}.include?(config_spot_price)
          spot_price = ""
        else
          spot_price = config_spot_price
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
          spot_options: spot_options,
        }

        # The preferred way to create a spot instance is via request_spot_instances()
        # However, it does not allow for tagging to occur at creation time.
        # create_instances() allows creation of tagged spot instances, but does
        # not retry if the price could not be satisfied immediately.
        Retryable.retryable(
          tries: config[:spot_wait] / config[:retryable_sleep],
          sleep: lambda { |_n| config[:retryable_sleep] },
          on: ::Aws::EC2::Errors::SpotMaxPriceTooLow
        ) do |retries|
          c = retries * config[:retryable_sleep]
          t = config[:spot_wait]
          info "Waited #{c}/#{t}s for spot request to become fulfilled."
          ec2.create_instance(instance_data)
        end
      end

      # Normally we could use `server.wait_until_running` but we actually need
      # to check more than just the instance state
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

          if ready && ( hostname.nil? || hostname == "" )
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
              output = server.console_output.output
              unless output.nil?
                output = Base64.decode64(output)
                debug "Console output: --- \n#{output}"
              end
              ready = !!(output =~ /Windows is Ready to use/)
            end
          end
          ready
        end
      end

      # Poll a block, waiting for it to return true. If it does not succeed
      # within the configured time we destroy the instance to save people money
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

      def fetch_windows_admin_password(server, state)
        wait_with_destroy(server, state, "to fetch windows admin password") do |aws_instance|
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

      #
      # Ordered mapping from config name to Fog name. Ordered by preference
      # when looking up hostname.
      #
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
      def hostname(server, interface_type = nil)
        if interface_type
          interface_type = INTERFACE_TYPES.fetch(interface_type) do
            raise Kitchen::UserError, "Invalid interface [#{interface_type}]"
          end
          server.send(interface_type)
        else
          potential_hostname = nil
          INTERFACE_TYPES.values.each do |type|
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
      def sudo_command
        instance.provisioner[:sudo] ? instance.provisioner[:sudo_command].to_s : ""
      end

      def create_ec2_json(state)
        if windows_os?
          cmd = "New-Item -Force C:\\chef\\ohai\\hints\\ec2.json -ItemType File"
        else
          debug "Using sudo_command='#{sudo_command}' for ohai hints"
          cmd = "#{sudo_command} mkdir -p /etc/chef/ohai/hints; #{sudo_command} touch /etc/chef/ohai/hints/ec2.json"
        end
        instance.transport.connection(state).execute(cmd)
      end

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
        if !(instance.transport[:username] =~ /administrator/i) && instance.transport[:password]
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

      def image_info(image)
        root_device = image.block_device_mappings
          .find { |b| b.device_name == image.root_device_name }
        volume_type = " #{root_device.ebs.volume_type}" if root_device && root_device.ebs

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
                { cidr_ip: cidr_ip }
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
          Array.new(8) { rand(36).to_s(36) }.join(""),
        ]
        # In a perfect world this would generate the key locally and use ImportKey
        # instead for better security, but given the use case that is very likely
        # to rapidly exhaust local entropy by creating a lot of keys. So this is
        # probably fine. If you want very high security, probably don't use this
        # feature anyway.
        resp = ec2.client.create_key_pair(key_name: "kitchen-#{name_parts.join("-")}", key_type: config[:aws_ssh_key_type])
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
          warn("#{e}")
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
        File.unlink("#{config[:kitchen_root]}/.kitchen/#{instance.name}.pem")
      end

    end
  end
end
