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

require "base64"
require "aws-sdk"

module Kitchen

  module Driver

    class Aws

      # A class for encapsulating the instance payload logic
      #
      # @author Tyler Ball <tball@chef.io>
      class InstanceGenerator

        attr_reader :config, :ec2, :logger

        def initialize(config, ec2, logger)
          @config = config
          @ec2 = ec2
          @logger = logger
        end

        # search for the subnet_id using the provided subnet_filter
        # @return [String] the subnet ID
        def subnet_id_from_filter
          subnet = ::Aws::EC2::Client.
            new(:region => config[:region]).describe_subnets(
              :filters => [
                {
                  :name   => "tag:#{config[:subnet_filter][:tag]}",
                  :values => [config[:subnet_filter][:value]],
                },
              ]
            )[0][0].subnet_id

          # fail if we didn't return anything
          if subnet.nil?
            warn "The subnet tagged '#{config[:subnet_filter][:tag]}\
            #{config[:subnet_filter][:value]}' does not exist!"
            exit!
          end
          subnet
        end

        # search for the security_group_ids using the provided security_group_filter
        # @return [Array] security group IDs
        def security_group_ids_from_filter
          security_group = ::Aws::EC2::Client.
              new(:region => config[:region]).describe_security_groups(
              :filters => [
                  {
                      :name => "tag:#{config[:security_group_filter][:tag]}",
                      :values => [config[:security_group_filter][:value]],
                  },
              ]
            )[0][0]

          # fail if we didn't return anything
          if security_group.nil?
            warn "The group tagged '#{config[:security_group_filter][:tag]}\
            #{config[:security_group_filter][:value]}' does not exist!"
            exit!
          end
          [security_group.group_id]
        end

        # security_group_ids if provided or if security_group_filter provided
        # the matching security group IDs using that filter in the account
        # @return [Array] the security group IDs
        def security_group_ids
          @security_ids ||= begin
            if config[:security_group_ids]
              Array(config[:security_group_ids])
            elsif config[:security_group_filter]
              security_group_ids_from_filter
            end
          end
        end

        # the provided subnet_id or if a subnet_filter is provided
        # a matching subnet ID using that filter in the account
        # @return [String, nil] the subnet ID or nil
        def subnet_id
          @subnet_ids ||= begin
          # lookup the subnet if we have a filter set and no subnet_id set
            if config[:subnet_id]
              config[:subnet_id]
            elsif config[:subnet_filter]
              subnet_id_from_filter
            end
          end
        end

        # parsed user data
        # @return [String, nil] user data or nil
        def prepared_user_data
          # If user_data is a file reference, lets read it as such
          @user_data ||= begin
            return nil if config[:user_data].nil?

            raw_user_data = config.fetch(:user_data)
            if !raw_user_data.include?("\0") && ::File.file?(raw_user_data)
              raw_user_data = ::File.read(raw_user_data)
            end

            ::Base64.encode64(raw_user_data)
          end
        end

        # process user passed availability zone. Make sure it's
        # lowercase and is in region and zone format. us-east-1a
        # @return [String, nil] the availability zone or nil
        def availability_zone
          return unless config[:availability_zone]
          az = config[:availability_zone]
          if az =~ /^[a-z]$/i
            az = "#{config[:region]}#{az}"
          end
          az.downcase
        end

        # placement hash for aws connection. Adds tenancy and AZ
        # information if provided
        # @return [Hash] the placement hash
        def placement
          az_val = availability_zone
          vals = {}
          vals[:tenancy] = config[:tenancy] if config[:tenancy]
          vals[:availability_zone] = az_val if az_val
          vals
        end

        # network interface configuration information
        def network_interfaces
          if !config.fetch(:associate_public_ip, nil).nil?
            [{
              :device_index => 0,
              :associate_public_ip_address => config[:associate_public_ip],
              :delete_on_termination => true,
            }]
          end
        end

        # Transform the provided config into the hash to send to AWS.  Some fields
        # can be passed in null, others need to be ommitted if they are null
        def ec2_instance_data
          i = {
            :instance_type          => config[:instance_type],
            :ebs_optimized          => config[:ebs_optimized],
            :image_id               => config[:image_id],
            :key_name               => config[:aws_ssh_key_id],
            :subnet_id              => subnet_id,
            :private_ip_address     => config[:private_ip_address],
          }

          unless placement.empty?
            i[:placement] = placement
          end

          unless config[:block_device_mappings].nil? || config[:block_device_mappings].empty?
            i[:block_device_mappings] = config[:block_device_mappings]
          end
          i[:security_group_ids] = security_group_ids if security_group_ids
          i[:user_data] = prepared_user_data if prepared_user_data
          if config[:iam_profile_name]
            i[:iam_instance_profile] = { :name => config[:iam_profile_name] }
          end
          unless config[:instance_initiated_shutdown_behavior].nil? ||
              config[:instance_initiated_shutdown_behavior].empty?
            i[:instance_initiated_shutdown_behavior] = config[:instance_initiated_shutdown_behavior]
          end
          i[:network_interfaces] = network_interfaces
          # If specifying `:network_interfaces` in the request, you must specify
          # network specific configs in the network_interfaces block and not at
          # the top level
          if i[:network_interfaces]
            if config[:subnet_id]
              i[:network_interfaces][0][:subnet_id] = i.delete(:subnet_id)
            end
            if config[:private_ip_address]
              i[:network_interfaces][0][:private_ip_address] = i.delete(:private_ip_address)
            end
            if config[:security_group_ids]
              i[:network_interfaces][0][:groups] = i.delete(:security_group_ids)
            end
          end
          i
        end

      end

    end

  end

end
