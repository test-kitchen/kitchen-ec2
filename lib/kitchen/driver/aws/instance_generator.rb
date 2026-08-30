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
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "base64" unless defined?(Base64)
require "aws-sdk-ec2"

module Kitchen
  module Driver
    class Aws
      # A class for encapsulating the instance payload logic
      #
      # @author Tyler Ball <tball@chef.io>
      class InstanceGenerator
        # @return [Hash] the driver config the payload is built from
        attr_reader :config

        # @return [Kitchen::Driver::Aws::Client] the driver's EC2 client wrapper
        attr_reader :ec2

        # @return [Kitchen::Logger] the logger to report through
        attr_reader :logger

        # @param config [Hash] the driver config
        # @param ec2 [Kitchen::Driver::Aws::Client] the driver's EC2 client wrapper
        # @param logger [Kitchen::Logger] the logger to report through
        def initialize(config, ec2, logger)
          @config = config
          @ec2 = ec2
          @logger = logger
        end

        # Build the RunInstances payload from the driver config.
        #
        # Some EC2 fields accept an explicit nil and others must be omitted
        # entirely, so optional settings are added conditionally rather than
        # always being present with a nil value.
        #
        # Two lookups happen here as a side effect, because both need to resolve
        # before the payload can be built: a subnet is resolved from
        # `subnet_filter` (and written back into the config), and security
        # groups are resolved from `security_group_filter` within that subnet's
        # VPC. Both are skipped when the corresponding ID is already set.
        #
        # @return [Hash] parameters for `Aws::EC2::Resource#create_instances`
        # @raise [RuntimeError] when a subnet or security group filter matches
        #   nothing, since launching into an unintended network is worse than
        #   failing
        # @see https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Resource.html#create_instances-instance_method
        def ec2_instance_data
          # Support for looking up security group id and subnet id using tags.
          vpc_id = nil
          client = ::Aws::EC2::Client.new(region: config[:region])
          if config[:subnet_id].nil? && config[:subnet_filter]
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
            raise "Subnets with tags '#{filters}' not found during security group creation" if subnets.empty?

            # => Select the least-populated subnet if we have multiple matches
            subnet = subnets.max_by { |s| s[:available_ip_address_count] }
            vpc_id = subnet.vpc_id
            config[:subnet_id] = subnet.subnet_id
          end

          if config[:security_group_ids].nil? && config[:security_group_filter]
            # => Grab the VPC in the case a Subnet ID rather than Filter was set
            vpc_id ||= security_group_search_vpc_id(client)
            security_groups = []
            filters = [config[:security_group_filter]].flatten
            filters.each do |sg_filter|
              # Built up rather than assigned, so that a filter carrying both a
              # name and a tag searches on both. Assigning meant the tag
              # replaced the name outright, silently widening the search to
              # whatever else carried that tag.
              criteria = []
              if sg_filter[:name]
                criteria << { name: "group-name", values: [sg_filter[:name]] }
              end
              if sg_filter[:tag]
                criteria << { name: "tag:#{sg_filter[:tag]}", values: [sg_filter[:value]] }
              end

              # Refused rather than sent: describe_security_groups with no
              # filters returns every security group in the region, and all of
              # them were then attached to the instance.
              if criteria.empty?
                raise "A security_group_filter needs a `name` or a `tag`, but " \
                      "#{sg_filter.inspect} has neither."
              end

              # Only when a VPC is known. A name or tag has already narrowed the
              # search, so leaving this off is not the unfiltered request the
              # check above exists to prevent.
              criteria << { name: "vpc-id", values: [vpc_id] } if vpc_id

              security_group = client.describe_security_groups(filters: criteria).security_groups

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
            instance_tag_spec = { resource_type: "instance", tags: }
            volume_tag_spec = { resource_type: "volume", tags: }
            i[:tag_specifications] = [instance_tag_spec, volume_tag_spec]
          end

          unless config[:block_device_mappings].nil? || config[:block_device_mappings].empty?
            i[:block_device_mappings] = config[:block_device_mappings]
          end
          i[:security_group_ids] = Array(config[:security_group_ids]) if config[:security_group_ids]
          i[:metadata_options] = config[:metadata_options] if config[:metadata_options]
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
            if config[:associate_ipv6]
              i[:network_interfaces][0][:ipv_6_address_count] = 1
            end
          end
          # A bare zone letter is a shorthand for that zone within the
          # configured region, so "b" in us-west-2 becomes "us-west-2b".
          availability_zone = config[:availability_zone]
          if availability_zone
            if /^[a-z]$/i.match?(availability_zone)
              availability_zone = "#{config[:region]}#{availability_zone}"
            end
            i[:placement] = { availability_zone: availability_zone.downcase }
          end
          tenancy = config[:tenancy]
          if tenancy
            if i.key?(:placement)
              i[:placement][:tenancy] = tenancy
            else
              i[:placement] = { tenancy: }
            end
          end
          placement = config[:placement]
          if placement
            unless i.key?(:placement)
              i[:placement] = {}
            end
            if placement[:affinity]
              i[:placement][:affinity] = placement[:affinity]
            end
            if placement[:availability_zone]
              i[:placement][:availability_zone] = placement[:availability_zone]
            end
            if placement[:group_id] && !placement[:group_name]
              i[:placement][:group_id] = placement[:group_id]
            end
            if placement[:group_name] && !placement[:group_id]
              i[:placement][:group_name] = placement[:group_name]
            end
            if placement[:host_id]
              i[:placement][:host_id] = placement[:host_id]
            end
            if placement[:host_resource_group_arn]
              i[:placement][:host_resource_group_arn] = placement[:host_resource_group_arn]
            end
            if placement[:partition_number]
              i[:placement][:partition_number] = placement[:partition_number]
            end
            if placement[:tenancy]
              i[:placement][:tenancy] = placement[:tenancy]
            end
          end
          # RunInstances calls this `license_specifications`. The driver option
          # is `licenses`, and the payload key used to match the option rather
          # than the API, which no EC2 API accepts.
          license_specifications = config[:licenses]
          if license_specifications
            i[:license_specifications] = license_specifications.map do |license|
              { license_configuration_arn: license[:license_configuration_arn] }
            end
          end
          unless config[:instance_initiated_shutdown_behavior].nil? ||
              config[:instance_initiated_shutdown_behavior].empty?
            i[:instance_initiated_shutdown_behavior] = config[:instance_initiated_shutdown_behavior]
          end
          i
        end

        # The VPC to look for security groups in.
        #
        # Security group names are unique only within a VPC, so the search is
        # scoped to the VPC the instance will launch into. Which VPC that is
        # depends on how the subnet was chosen:
        #
        # - a named `subnet_id` decides it, so the subnet is described for it
        # - no subnet at all means EC2 launches into the account's default VPC,
        #   so that is what gets searched
        #
        # The second case used to describe a subnet with an ID of nil and then
        # read `vpc_id` off the empty result, so a `security_group_filter` on
        # its own -- a documented combination, and the natural one in a default
        # VPC account -- died with `undefined method 'vpc_id' for nil` before
        # anything was launched.
        #
        # An account with no default VPC returns nil, and the caller then
        # searches on the name or tag alone.
        #
        # @param client [Aws::EC2::Client] the client to query with
        # @return [String, nil] the VPC ID, or nil when there is no default VPC
        # @raise [RuntimeError] when a named subnet does not exist, which would
        #   otherwise surface as the same nil dereference
        def security_group_search_vpc_id(client)
          unless config[:subnet_id]
            default_vpc = client.describe_vpcs(
              filters: [{ name: "isDefault", values: %w{true} }]
            ).vpcs.first

            return default_vpc&.vpc_id
          end

          subnet = client.describe_subnets(subnet_ids: [config[:subnet_id]]).subnets.first
          unless subnet
            raise "Subnet #{config[:subnet_id]} not found while resolving security_group_filter."
          end

          subnet.vpc_id
        end

        # The user data script, base64 encoded as EC2 requires.
        #
        # The configured value is treated as a file path when it names an
        # existing file, and as inline script content otherwise. Content
        # containing a null byte is always treated as inline, both because a
        # path cannot contain one and because `File.file?` would raise on it.
        #
        # The result is memoized: the file is read once per driver, not once per
        # call.
        #
        # @return [String, nil] base64 encoded user data, or nil when none is
        #   configured
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
