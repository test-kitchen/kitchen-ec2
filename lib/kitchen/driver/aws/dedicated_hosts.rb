module Kitchen
  module Driver
    module Mixins
      module DedicatedHosts
        # check if a suitable dedicated host is available
        # @return Boolean
        def host_available?
          !hosts_with_capacity.empty?
        end

        # get dedicated host with capacity for instance type
        # @return Aws::EC2::Types::Host
        def hosts_with_capacity
          hosts_managed.select do |host|
            # T-instance hosts do not report available capacity and can be overprovisioned
            if host.available_capacity.nil?
              true
            else
              instance_capacity = host.available_capacity.available_instance_capacity
              capacity_for_type = instance_capacity.detect { |cap| cap.instance_type == config[:instance_type] }
              capacity_for_type.available_capacity > 0
            end
          end
        end

        # check if host has no instances running
        # @param host_id [Aws::EC2::Types::Host] dedicated host
        # @return Boolean
        def host_unused?(host)
          host.instances.empty?
        end

        # get host data for host id
        # @param host_id [Aws::EC2::Types::Host] dedicated host
        # @return Array(Aws::EC2::Types::Host)
        def host_for_id(host_id)
          ec2.client.describe_hosts(host_ids: [host_id])&.first
        end

        # get dedicated hosts managed by Test Kitchen
        # @return Array(Aws::EC2::Types::Host)
        def hosts_managed
          response = ec2.client.describe_hosts(
            filter: [
              { name: "tag:ManagedBy", values: ["Test Kitchen"] },
            ]
          )

          response.hosts.select { |host| host.state == "available" }
        end

        # allocate new dedicated host for requested instance type
        # @return String host id
        def allocate_host
          unless allow_allocate_host?
            warn "ERROR: Attempted to allocate dedicated host but need environment variable TK_ALLOCATE_DEDICATED_HOST to be set"
            exit!
          end

          unless config[:availability_zone]
            warn "Attempted to allocate dedicated host but option 'availability_zone' is not set"
            exit!
          end

          info("Allocating dedicated host for #{config[:instance_type]} instances. This will incur additional cost")

          request = {
            availability_zone: config[:availability_zone],
            quantity: 1,

            auto_placement: "on",

            tag_specifications: [
              {
                resource_type: "dedicated-host",
                tags: [
                  { key: "ManagedBy", value: "Test Kitchen" },
                ],
              },
            ],
          }

          # ".metal" is a 1:1 association, everything else has multi-instance capability
          if instance_size_from_type(config[:instance_type]) == "metal"
            request[:instance_type] = config[:instance_type]
          else
            request[:instance_family] = instance_family_from_type(config[:instance_type])
          end

          response = ec2.client.allocate_hosts(request)
          response.host_ids.first
        end

        # deallocate a dedicated host
        # @param host_id [String] dedicated host id
        # @return Aws::EC2::Types::ReleaseHostsResult
        def deallocate_host(host_id)
          info("Deallocating dedicated host #{host_id}")

          response = ec2.client.release_hosts({ host_ids: [host_id] })
          unless response.unsuccessful.empty?
            warn "ERROR: Could not release dedicated host #{host_id}. Host may remain allocated and incur cost"
            exit!
          end
        end

        # return instance family from type
        # @param instance_type [String] type in format family.size
        # @return String instance family
        def instance_family_from_type(instance_type)
          instance_type.split(".").first
        end

        # return instance size from type
        # @param instance_type [String] type in format family.size
        # @return String instance size
        def instance_size_from_type(instance_type)
          instance_type.split(".").last
        end

        # check config, if host allocation is enabled
        # @return Boolean
        def allow_allocate_host?
          config[:allocate_dedicated_host]
        end

        # check config, if host deallocation is enabled
        # @return Boolean
        def allow_deallocate_host?
          config[:deallocate_dedicated_host]
        end
      end
    end
  end
end
