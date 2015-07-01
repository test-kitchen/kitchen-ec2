# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2015, Fletcher Nichol
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

require "benchmark"
require "json"
require "kitchen"
require_relative "ec2_version"
require_relative "aws/client"
require_relative "aws/instance_generator"
require "aws-sdk-core/waiters/errors"
require "ubuntu_ami"

module Kitchen

  module Driver

    # Amazon EC2 driver for Test Kitchen.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class Ec2 < Kitchen::Driver::Base # rubocop:disable Metrics/ClassLength

      kitchen_driver_api_version 2

      plugin_version Kitchen::Driver::EC2_VERSION

      default_config :region,             ENV["AWS_REGION"] || "us-east-1"
      default_config :shared_credentials_profile, nil
      default_config :availability_zone,  nil
      default_config :flavor_id,          nil
      default_config :instance_type,      nil
      default_config :ebs_optimized,      false
      default_config :security_group_ids, nil
      default_config :tags,                "created-by" => "test-kitchen"
      default_config :user_data do |driver|
        if driver.windows_os?
          driver.default_windows_user_data
        end
      end
      default_config :private_ip_address, nil
      default_config :iam_profile_name,   nil
      default_config :price,              nil
      default_config :retryable_tries,    60
      default_config :retryable_sleep,    5
      default_config :aws_access_key_id,  nil
      default_config :aws_secret_access_key, nil
      default_config :aws_session_token,  nil
      default_config :aws_ssh_key_id,     ENV["AWS_SSH_KEY_ID"]
      default_config :image_id do |driver|
        driver.default_ami
      end
      default_config :username,            nil
      default_config :associate_public_ip, nil
      default_config :interface,           nil
      default_config :http_proxy,          ENV["HTTPS_PROXY"] || ENV["HTTP_PROXY"]

      required_config :aws_ssh_key_id
      required_config :image_id

      def self.validation_warn(driver, old_key, new_key)
        driver.warn "WARN: The driver[#{driver.class.name}] config key `#{old_key}` " \
          "is deprecated, please use `#{new_key}`"
      end

      # TODO: remove these in the next major version of TK
      deprecated_configs = [:ebs_volume_size, :ebs_delete_on_termination, :ebs_device_name]
      deprecated_configs.each do |d|
        validations[d] = lambda do |attr, val, driver|
          unless val.nil?
            validation_warn(driver, attr, "block_device_mappings")
          end
        end
      end
      validations[:ssh_key] = lambda do |attr, val, driver|
        unless val.nil?
          validation_warn(driver, attr, "transport.ssh_key")
        end
      end
      validations[:ssh_timeout] = lambda do |attr, val, driver|
        unless val.nil?
          validation_warn(driver, attr, "transport.connection_timeout")
        end
      end
      validations[:ssh_retries] = lambda do |attr, val, driver|
        unless val.nil?
          validation_warn(driver, attr, "transport.connection_retries")
        end
      end
      validations[:username] = lambda do |attr, val, driver|
        unless val.nil?
          validation_warn(driver, attr, "transport.username")
        end
      end
      validations[:flavor_id] = lambda do |attr, val, driver|
        unless val.nil?
          validation_warn(driver, attr, "instance_type")
        end
      end

      default_config :block_device_mappings, nil
      validations[:block_device_mappings] = lambda do |_attr, val, _driver|
        unless val.nil?
          val.each do |bdm|
            unless bdm.keys.include?(:ebs_volume_size) &&
                bdm.keys.include?(:ebs_delete_on_termination) &&
                bdm.keys.include?(:ebs_device_name)
              raise "Every :block_device_mapping must include the keys :ebs_volume_size, " \
                ":ebs_delete_on_termination and :ebs_device_name"
            end
          end
        end
      end

      # The access key/secret are now using the priority list AWS uses
      # Providing these inside the .kitchen.yml is no longer recommended
      validations[:aws_access_key_id] = lambda do |attr, val, driver|
        unless val.nil?
          driver.warn "WARN: #{attr} has been deprecated, please use " \
            "ENV['AWS_ACCESS_KEY_ID'] or ~/.aws/credentials.  See " \
            "the README for more details"
        end
      end
      validations[:aws_secret_access_key] = lambda do |attr, val, driver|
        unless val.nil?
          driver.warn "WARN: #{attr} has been deprecated, please use " \
            "ENV['AWS_SECRET_ACCESS_KEY'] or ~/.aws/credentials.  See " \
            "the README for more details"
        end
      end
      validations[:aws_session_token] = lambda do |attr, val, driver|
        unless val.nil?
          driver.warn "WARN: #{attr} has been deprecated, please use " \
            "ENV['AWS_SESSION_TOKEN'] or ~/.aws/credentials.  See " \
            "the README for more details"
        end
      end

      # A lifecycle method that should be invoked when the object is about
      # ready to be used. A reference to an Instance is required as
      # configuration dependant data may be access through an Instance. This
      # also acts as a hook point where the object may wish to perform other
      # last minute checks, validations, or configuration expansions.
      #
      # @param instance [Instance] an associated instance
      # @return [self] itself, for use in chaining
      # @raise [ClientError] if instance parameter is nil
      def finalize_config!(instance)
        super

        if config[:availability_zone].nil?
          config[:availability_zone] = config[:region] + "b"
        elsif config[:availability_zone] =~ /^[a-z]$/
          config[:availability_zone] = config[:region] + config[:availability_zone]
        end
        # TODO: when we get rid of flavor_id, move this to a default
        if config[:instance_type].nil?
          config[:instance_type] = config[:flavor_id] || "m1.small"
        end

        self
      end

      def create(state) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        copy_deprecated_configs(state)
        return if state[:server_id]

        info(Kitchen::Util.outdent!(<<-END))
          If you are not using an account that qualifies under the AWS
          free-tier, you may be charged to run these suites. The charge
          should be minimal, but neither Test Kitchen nor its maintainers
          are responsible for your incurred costs.
        END

        if config[:price]
          # Spot instance when a price is set
          server = submit_spot(state)
        else
          # On-demand instance
          server = submit_server
        end
        info("Instance <#{server.id}> requested.")
        ec2.client.wait_until(
          :instance_exists,
          :instance_ids => [server.id]
        )
        tag_server(server)

        state[:server_id] = server.id
        info("EC2 instance <#{state[:server_id]}> created.")
        wait_until_ready(server, state)

        if windows_os? &&
            instance.transport[:username] =~ /administrator/i &&
            instance.transport[:password].nil?
          # If we're logging into the administrator user and a password isn't
          # supplied, try to fetch it from the AWS instance
          fetch_windows_admin_password(server, state)
        end

        info("EC2 instance <#{state[:server_id]}> ready.")
        instance.transport.connection(state).wait_until_ready
        create_ec2_json(state)
        debug("ec2:create '#{state[:hostname]}'")
      end

      def destroy(state)
        return if state[:server_id].nil?

        server = ec2.get_instance(state[:server_id])
        unless server.nil?
          instance.transport.connection(state).close
          server.terminate
        end
        if state[:spot_request_id]
          debug("Deleting spot request <#{state[:server_id]}>")
          ec2.client.cancel_spot_instance_requests(
            :spot_instance_request_ids => [state[:spot_request_id]]
          )
          state.delete(:spot_request_id)
        end
        info("EC2 instance <#{state[:server_id]}> destroyed.")
        state.delete(:server_id)
        state.delete(:hostname)
      end

      def ubuntu_ami(region, platform_name)
        release = amis["ubuntu_releases"][platform_name]
        Ubuntu.release(release).amis.find do |ami|
          ami.arch == "amd64" &&
            ami.root_store == "instance-store" &&
            ami.region == region &&
            ami.virtualization_type == "paravirtual"
        end
      end

      def default_ami
        if instance.platform.name.start_with?("ubuntu")
          ami = ubuntu_ami(config[:region], instance.platform.name)
          ami && ami.name
        else
          region = amis["regions"][config[:region]]
          region && region[instance.platform.name]
        end
      end

      def ec2
        @ec2 ||= Aws::Client.new(
          config[:region],
          config[:shared_credentials_profile],
          config[:aws_access_key_id],
          config[:aws_secret_access_key],
          config[:aws_session_token],
          config[:http_proxy]
        )
      end

      def instance_generator
        @instance_generator ||= Aws::InstanceGenerator.new(config, ec2, instance.logger)
      end

      # This copies transport config from the current config object into the
      # state.  This relies on logic in the transport that merges the transport
      # config with the current state object, so its a bad coupling.  But we
      # can get rid of this when we get rid of these deprecated configs!
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def copy_deprecated_configs(state)
        if config[:ssh_timeout]
          state[:connection_timeout] = config[:ssh_timeout]
        end
        if config[:ssh_retries]
          state[:connection_retries] = config[:ssh_retries]
        end
        if config[:username]
          state[:username] = config[:username]
        elsif instance.transport[:username] == instance.transport.class.defaults[:username]
          # If the transport has the default username, copy it from amis.json
          # This duplicated old behavior but I hate amis.json
          ami_username = amis["usernames"][instance.platform.name]
          state[:username] = ami_username if ami_username
        end
        if config[:ssh_key]
          state[:ssh_key] = config[:ssh_key]
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Fog AWS helper for creating the instance
      def submit_server
        debug("Creating EC2 Instance..")
        instance_data = instance_generator.ec2_instance_data
        instance_data[:min_count] = 1
        instance_data[:max_count] = 1
        ec2.create_instance(instance_data)
      end

      def submit_spot(state) # rubocop:disable Metrics/AbcSize
        debug("Creating EC2 Spot Instance..")
        request_data = {}
        request_data[:spot_price] = config[:price].to_s
        request_data[:launch_specification] = instance_generator.ec2_instance_data

        response = ec2.client.request_spot_instances(request_data)
        spot_request_id = response[:spot_instance_requests][0][:spot_instance_request_id]
        # deleting the instance cancels the request, but deleting the request
        # does not affect the instance
        state[:spot_request_id] = spot_request_id
        ec2.client.wait_until(
          :spot_instance_request_fulfilled,
          :spot_instance_request_ids => [spot_request_id]
        ) do |w|
          w.max_attempts = config[:retryable_tries]
          w.delay = config[:retryable_sleep]
          w.before_attempt do |attempts|
            c = attempts * config[:retryable_sleep]
            t = config[:retryable_tries] * config[:retryable_sleep]
            info "Waited #{c}/#{t}s for spot request <#{spot_request_id}> to become fulfilled."
          end
        end
        ec2.get_instance_from_spot_request(spot_request_id)
      end

      def tag_server(server)
        tags = []
        config[:tags].each do |k, v|
          tags << { :key => k, :value => v }
        end
        server.create_tags(:tags => tags)
      end

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
          if ready && windows_os?
            output = server.console_output.output
            unless output.nil?
              output = Base64.decode64(output)
              debug "Console output: --- \n#{output}"
            end
            ready = !!(output =~ /Windows is Ready to use/)
          end
          ready
        end
      end

      # rubocop:disable Lint/UnusedBlockArgument
      def fetch_windows_admin_password(server, state)
        wait_with_destroy(server, state, "to fetch windows admin password") do |aws_instance|
          enc = server.client.get_password_data(
            :instance_id => state[:server_id]
          ).password_data
          # Password data is blank until password is available
          !enc.nil? && !enc.empty?
        end
        pass = server.decrypt_windows_password(instance.transport[:ssh_key])
        state[:password] = pass
        info("Retrieved Windows password for instance <#{state[:server_id]}>.")
      end
      # rubocop:enable Lint/UnusedBlockArgument

      def wait_with_destroy(server, state, status_msg, &block)
        wait_log = proc do |attempts|
          c = attempts * config[:retryable_sleep]
          t = config[:retryable_tries] * config[:retryable_sleep]
          info "Waited #{c}/#{t}s for instance <#{state[:server_id]}> #{status_msg}."
        end
        begin
          server.wait_until(
            :max_attempts => config[:retryable_tries],
            :delay => config[:retryable_sleep],
            :before_attempt => wait_log,
            &block
          )
        rescue ::Aws::Waiters::Errors::WaiterFailed
          error("Ran out of time waiting for the server with id [#{state[:server_id]}]" \
            " #{status_msg}, attempting to destroy it")
          destroy(state)
          raise
        end
      end

      def amis
        @amis ||= begin
          json_file = File.join(File.dirname(__FILE__),
            %w[.. .. .. data amis.json])
          JSON.load(IO.read(json_file))
        end
      end

      #
      # Ordered mapping from config name to Fog name.  Ordered by preference
      # when looking up hostname.
      #
      INTERFACE_TYPES =
        {
          "dns" => "public_dns_name",
          "public" => "public_ip_address",
          "private" => "private_ip_address"
        }

      #
      # Lookup hostname of provided server.  If interface_type is provided use
      # that interface to lookup hostname.  Otherwise, try ordered list of
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

      def create_ec2_json(state)
        if windows_os?
          cmd = "New-Item -Force C:\\chef\\ohai\\hints\\ec2.json -ItemType File"
        else
          cmd = "sudo mkdir -p /etc/chef/ohai/hints;sudo touch /etc/chef/ohai/hints/ec2.json"
        end
        instance.transport.connection(state).execute(cmd)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/LineLength
      def default_windows_user_data
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
        $logfile="C:\\Program Files\\Amazon\\Ec2ConfigService\\Logs\\kitchen-ec2.log"
        #PS Remoting and & winrm.cmd basic config
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        & winrm.cmd set winrm/config '@{MaxTimeoutms="1800000"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxShellsPerUser="50"}' >> $logfile
        #Server settings - support username/password login
        & winrm.cmd set winrm/config/service/auth '@{Basic="true"}' >> $logfile
        & winrm.cmd set winrm/config/service '@{AllowUnencrypted="true"}' >> $logfile
        & winrm.cmd set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' >> $logfile
        #Firewall Config
        & netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any  >> $logfile
        #{custom_admin_script}
        </powershell>
        EOH
      end
      # rubocop:enable Metrics/MethodLength, Metrics/LineLength

    end
  end
end
