# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2012, Fletcher Nichol
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
require "fog"
require "kitchen"
require "erb"
require "thor/actions/file_manipulation"

module Kitchen
  module Driver
    # Amazon EC2 driver for Test Kitchen with native
    # AWS generated Windows password support
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class Ec2 < Kitchen::Driver::Base
      include Thor::Actions

      default_config :region,             "us-east-1"
      default_config :availability_zone,  "us-east-1b"
      default_config :flavor_id,          "m1.small"
      default_config :ebs_optimized,      false
      default_config :security_group_ids, ["default"]
      default_config :tags,                "created-by" => "test-kitchen"
      default_config :user_data,          nil
      default_config :iam_profile_name,   nil
      default_config :price,              nil
      default_config :aws_access_key_id do |_driver|
        ENV["AWS_ACCESS_KEY"] || ENV["AWS_ACCESS_KEY_ID"]
      end
      default_config :aws_secret_access_key do |_driver|
        ENV["AWS_SECRET_KEY"] || ENV["AWS_SECRET_ACCESS_KEY"]
      end
      default_config :aws_session_token do |_driver|
        ENV["AWS_SESSION_TOKEN"] || ENV["AWS_TOKEN"]
      end
      default_config :aws_ssh_key_id do |_driver|
        ENV["AWS_SSH_KEY_ID"]
      end
      default_config :image_id do |driver|
        driver.default_ami
      end
      default_config :username do |driver|
        driver.default_username
      end
      default_config :password do |driver|
        driver.default_password
      end
      default_config :endpoint do |driver|
        "https://ec2.#{driver[:region]}.amazonaws.com/"
      end

      default_config :interface, nil
      default_config :associate_public_ip do |driver|
        driver.default_public_ip_association
      end
      default_config :ssh_timeout, 1
      default_config :ssh_retries, 3

      required_config :aws_access_key_id
      required_config :aws_secret_access_key
      required_config :aws_ssh_key_id
      required_config :image_id

      # Creating a new instance
      # rubocop:disable all
      def create(state)
        return if state[:server_id]
        state[:port] = default_port
        state[:password] = config[:password] if config[:password]
        state[:username] = config[:username] if config[:username]

        # TODO: are these used by the transport yet?
        state[:ssh_timeout] = config[:ssh_timeout]
        state[:ssh_retries] = config[:ssh_retries]

        info(<<-MSG)
Creating <#{state[:server_id]}>...
If you are not using an account that qualifies under the AWS
free-tier, you may be charged to run these suites. The charge
should be minimal, but neither Test Kitchen nor its maintainers
are responsible for your incurred costs.
MSG

        if config[:price]
          # Spot instance when a price is set
          server = submit_spot
        else
          # On-demand instance
          server = submit_server
        end

        state[:server_id] = server.id

        info("EC2 instance <#{state[:server_id]}> created.")

        # Server preparation
        server.wait_for do
          print "."
          # Euca instances often report ready before they have an IP
          ready? && !public_ip_address.nil? && public_ip_address != "0.0.0.0"
        end
        print "(Server Ready)"
        state[:hostname] = hostname(server)

        create_windows_host!(state)
        debug("Credentials: #{state[:username]} #{state[:password]}")

        debug("Waiting for transport")
        transport.connection(state) do |c|
          c.wait_for_connection
        end
        print "(Transport Ready)"

        debug("ec2:create '#{state[:hostname]}'")
      rescue Fog::Errors::Error, Excon::Errors::Error => ex
        raise ActionFailed, ex.message
      end
      # rubocop:enable all

      def create_windows_host!(state)
        # Windows preparartion
        if transport.name.casecmp("winrm") == 0
          debug("Waiting for Windows")
          $stdout.sync = true
          until windows_ready?(state)
            putc "."
            sleep(10)
          end
          print "(Windows Ready)"

          # If we want to use the EC2 generated Admin password
          if config[:username].casecmp("Administrator") != 0
            print("Using static credentials")
          else
            print("Fetching EC2 generated credentials")
            config[:password] = windows_password(state)
            state[:password] = config[:password]
          end
        end
      end

      # Terminating the test instance
      def destroy(state)
        return if state[:server_id].nil?

        server = connection.servers.get(state[:server_id])
        server.destroy unless server.nil?
        info("EC2 instance <#{state[:server_id]}> destroyed.")
        state.delete(:server_id)
        state.delete(:hostname)
      end

      # Helper method to map a regial AMI for the OS
      def default_ami
        region = amis["regions"][config[:region]]
        region && region[instance.platform.name.downcase]
      end

      # Helper method to choose the admin user for the OS
      def default_username
        amis["usernames"][instance.platform.name.downcase] || "root"
      end

      def default_password
        amis["passwords"][instance.platform.name]
      end

      def default_public_ip_association
        !!config[:subnet_id]
      end

      private

      # Fog AWS helper method for creating connection
      def connection
        Fog::Compute.new(
          :provider => :aws,
          :aws_access_key_id => config[:aws_access_key_id],
          :aws_secret_access_key => config[:aws_secret_access_key],
          :aws_session_token => config[:aws_session_token],
          :region => config[:region],
          :endpoint => config[:endpoint]
        )
      end

      # Fog AWS helper for creating the instance
      def submit_server
        debug_server_config

        debug("Creating EC2 Instance..")
        connection.servers.create(common_ec2_instance)
      end

      def request_spot
        debug_server_config

        debug("Creating EC2 Spot Instance..")
        instance = common_ec2_instance
        instance[:price] = config[:price]
        instance[:instance_count] = config[:instance_count]
        connection.spot_requests.create(instance)
      end

      def submit_spot
        spot = request_spot
        info("Spot instance <#{spot.id}> requested.")
        info("Spot price is <#{spot.price}>.")
        spot.wait_for { print "."; spot.state == "active" }
        print "(spot active)"

        # tag assignation on the instance.
        if config[:tags]
          connection.create_tags(
            spot.instance_id,
            spot.tags
          )
        end
        connection.servers.get(spot.instance_id)
      end

      def common_ec2_instance
        {
          :availability_zone => config[:availability_zone],
          :groups => config[:security_group_ids],
          :tags => config[:tags],
          :flavor_id => config[:flavor_id],
          :ebs_optimized => config[:ebs_optimized],
          :image_id => config[:image_id],
          :key_name => config[:aws_ssh_key_id],
          :subnet_id => config[:subnet_id],
          :iam_instance_profile_name => config[:iam_profile_name],
          :associate_public_ip => config[:associate_public_ip],
          :user_data => prepared_user_data,
          :block_device_mapping => [{
            "Ebs.VolumeSize" => config[:ebs_volume_size],
            "Ebs.DeleteOnTermination" => config[:ebs_delete_on_termination],
            "DeviceName" => config[:ebs_device_name]
          }]
        }
      end

      # Method for preparing user_data for enabling PS Remoting if the selected
      # transport method is WinRM
      def prepared_user_data
        # If user_data is a file reference, lets read it as such
        unless config[:user_data].nil?
          if File.file?(config[:user_data])
            config[:user_data] = File.read(config[:user_data])
          end

          if transport.name.casecmp("winrm") == 0
            debug("Injecting WinRM config to EC2 user_data")

            # Preparing custom static admin user if we defined something other than Administrator
            if config[:username].casecmp("Administrator") != 0
              debug("Injecting custom Local Administrator:")

              custom_admin_script = open_template("custom_admin_script.erb")
              custom_admin_script = custom_admin_script.run(binding)
              debug("\n#{custom_admin_script}")
            end

            # Returning the fully constructed PowerShell script to user_data
            config[:user_data] = open_template("user_data.ps1.erb").run(binding)
          end
        end
        config[:user_data]
      end

      # Helper method to check whether Amazon reported a server Ready
      def windows_ready?(state)
        log = connection.get_console_output(state[:server_id]).data[:body]["output"]
        unless log.nil?
          debug("Console output: --- \n")
          debug(log)
        end
        !log.nil? && log =~ /Windows is Ready to use/
      end

      # Helper method to fetch and decrypt Windows password from EC2
      def windows_password(state)
        enc = connection.get_password_data(state[:server_id]).data[:body]["passwordData"].strip!
        enc = Base64.decode64(enc)
        rsa = OpenSSL::PKey::RSA.new aws_private_key
        rsa.private_decrypt(enc) if !enc.nil? && enc != ""
      rescue NoMethodError
        debug("Unable to fetch encrypted password")
        return ""
      rescue TypeError
        debug("Unable to decrypt password with AWS_PRIVATE_KEY")
        return ""
      end

      # Debug helper to display applied configuration
      # rubocop:disable Metrics/AbcSize
      def debug_server_config
        debug("EC2 Server Configuration")
        debug("ec2:region '#{config[:region]}'")
        debug("ec2:availability_zone '#{config[:availability_zone]}'")
        debug("ec2:flavor_id '#{config[:flavor_id]}'")
        debug("ec2:ebs_optimized '#{config[:ebs_optimized]}'")
        debug("ec2:image_id '#{config[:image_id]}'")
        debug("ec2:security_group_ids '#{config[:security_group_ids]}'")
        debug("ec2:tags '#{config[:tags]}'")
        debug("ec2:key_name '#{config[:aws_ssh_key_id]}'")
        debug("ec2:subnet_id '#{config[:subnet_id]}'")
        debug("ec2:iam_profile_name '#{config[:iam_profile_name]}'")
        debug("ec2:username '#{config[:username]}'")
        debug("ec2:password '#{config[:password]}'")
        debug("ec2:associate_public_ip '#{config[:associate_public_ip]}'")
        debug("ec2:user_data '#{config[:user_data]}'")
        debug("ec2:ssh_timeout '#{config[:ssh_timeout]}'")
        debug("ec2:ssh_retries '#{config[:ssh_retries]}'")
        debug("ec2:spot_price '#{config[:price]}'")
      end
      # rubocop:enable Metrics/AbcSize

      # Helper method for reading the Region-OS-AMI-UserName mapings to memory
      def amis
        @amis ||= begin
          json_file = File.join(File.dirname(__FILE__),
            %w[.. .. .. data amis.json])
          JSON.load(IO.read(json_file))
        end
      end

      # Networking helper
      def interface_types
        {
          "dns" => "dns_name",
          "public" => "public_ip_address",
          "private" => "private_ip_address"
        }
      end

      # Helper to get the hostname for the instance
      def hostname(server)
        if config[:interface]
          method = interface_types.fetch(config[:interface]) do
            fail Kitchen::UserError, "Invalid interface"
          end
          server.send(method)
        else
          server.dns_name || server.public_ip_address || server.private_ip_address
        end
      end

      # Get AWS Private Key
      def aws_private_key
        ENV["AWS_PRIVATE_KEY"] || ENV["AWS_SSH_KEY"] || (File.read config[:ssh_key])
      rescue
        debug("AWS_PRIVATE_KEY and AWS_SSH_KEY are not set.")
      end

      # TODO: is this the right way to do this?
      def open_template(name)
        @template_dir ||= File.expand_path(File.join(__dir__, "../../templates/windows"))
        ERB.new(File.read(File.join(@template_dir, name)))
      end
    end
  end
end
