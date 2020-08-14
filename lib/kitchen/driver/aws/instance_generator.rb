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
require "aws-sdk-ec2"

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

        # Transform the provided kitchen config into the hash we'll use to create the aws instance
        # can be passed in null, others need to be ommitted if they are null
        # Some fields can be passed in null, others need to be ommitted if they are null
        # @return [Hash]
        def ec2_instance_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          # Support for looking up security group id and subnet id using tags.
          vpc_id = nil
          client = ::Aws::EC2::Client.new(region: config[:region])
          if config[:subnet_id].nil? && config[:subnet_filter]
            subnets = client.describe_subnets(
              filters: [
                {
                  name: "tag:#{config[:subnet_filter][:tag]}",
                  values: [config[:subnet_filter][:value]],
                },
              ]
            ).subnets
            raise "The subnet tagged '#{config[:subnet_filter][:tag]}:#{config[:subnet_filter][:value]}' does not exist!" unless subnets.any?

            # => Select the least-populated subnet if we have multiple matches
            subnet = subnets.sort_by { |s| s[:available_ip_address_count] }.last
            vpc_id = subnet.vpc_id
            config[:subnet_id] = subnet.subnet_id
          end

          if config[:security_group_ids].nil? && config[:security_group_filter]
            # => Grab the VPC in the case a Subnet ID rather than Filter was set
            vpc_id ||= client.describe_subnets(subnet_ids: [config[:subnet_id]]).subnets[0].vpc_id
            security_groups = []
            filters = [config[:security_group_filter]].flatten
            filters.each do |sg_filter|
              r = {}
              if sg_filter[:name]
                r[:filters] = [
                  {
                    name: "group-name",
                    values: [sg_filter[:name]],
                  },
                  {
                    name: "vpc-id",
                    values: [vpc_id],
                  },
                ]
              end

              if sg_filter[:tag]
                r[:filters] = [
                  {
                    name: "tag:#{sg_filter[:tag]}",
                    values: [sg_filter[:value]],
                  },
                  {
                    name: "vpc-id",
                    values: [vpc_id],
                  },
                ]
              end

              security_group = client.describe_security_groups(r).security_groups

              if security_group.any?
                security_group.each { |sg| security_groups.push(sg.group_id) }
              else
                raise "A Security Group matching the following filter could not be found:\n#{sg_filter}"
              end
            end
            config[:security_group_ids] = security_groups
          end

          i = {
            instance_type: config[:instance_type],
            ebs_optimized: config[:ebs_optimized],
            image_id: config[:image_id],
            key_name: config[:aws_ssh_key_id],
            subnet_id: config[:subnet_id],
            private_ip_address: config[:private_ip_address],
            min_count: 1,
            max_count: 1,
          }

          if config[:tags] && !config[:tags].empty?
            tags = config[:tags].map do |k, v|
              # we convert the value to a string because
              # nils should be passed as an empty String
              # and Integers need to be represented as Strings
              { key: k, value: v.to_s }
            end
            instance_tag_spec = { resource_type: "instance", tags: tags }
            volume_tag_spec = { resource_type: "volume", tags: tags }
            i[:tag_specifications] = [instance_tag_spec, volume_tag_spec]
          end

          availability_zone = config[:availability_zone]
          if availability_zone
            if availability_zone =~ /^[a-z]$/i
              availability_zone = "#{config[:region]}#{availability_zone}"
            end
            i[:placement] = { availability_zone: availability_zone.downcase }
          end
          tenancy = config[:tenancy]
          if tenancy
            if i.key?(:placement)
              i[:placement][:tenancy] = tenancy
            else
              i[:placement] = { tenancy: tenancy }
            end
          end
          unless config[:block_device_mappings].nil? || config[:block_device_mappings].empty?
            i[:block_device_mappings] = config[:block_device_mappings]
          end
          i[:security_group_ids] = Array(config[:security_group_ids]) if config[:security_group_ids]
          i[:user_data] = prepared_user_data if prepared_user_data
          if config[:iam_profile_name]
            i[:iam_instance_profile] = { name: config[:iam_profile_name] }
          end
          unless config.fetch(:associate_public_ip, nil).nil?
            i[:network_interfaces] =
              [{
                device_index: 0,
                associate_public_ip_address: config[:associate_public_ip],
                delete_on_termination: true,
              }]
            # If specifying `:network_interfaces` in the request, you must specify
            # network specific configs in the network_interfaces block and not at
            # the top level
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
          availability_zone = config[:availability_zone]
          if availability_zone
            if availability_zone =~ /^[a-z]$/i
              availability_zone = "#{config[:region]}#{availability_zone}"
            end
            i[:placement] = { availability_zone: availability_zone.downcase }
          end
          tenancy = config[:tenancy]
          if tenancy
            if i.key?(:placement)
              i[:placement][:tenancy] = tenancy
            else
              i[:placement] = { tenancy: tenancy }
            end
          end
          unless config[:instance_initiated_shutdown_behavior].nil? ||
              config[:instance_initiated_shutdown_behavior].empty?
            i[:instance_initiated_shutdown_behavior] = config[:instance_initiated_shutdown_behavior]
          end
          i
        end

        def prepared_user_data
          # If user_data is a file reference, lets read it as such
          return nil if config[:user_data].nil?
          return @user_data if @user_data

          raw_user_data = config.fetch(:user_data)
          if !raw_user_data.include?("\0") && File.file?(raw_user_data)
            raw_user_data = File.read(raw_user_data)
          end

          @user_data = Base64.encode64(raw_user_data)
        end

      end

    end

  end

end
