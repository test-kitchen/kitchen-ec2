module Kitchen
  module Driver
    # Namespace for behavior mixed into {Kitchen::Driver::Ec2}.
    module Mixins
      # Allocation and release of EC2 Dedicated Hosts.
      #
      # A dedicated host is physical hardware reserved for one account, required
      # for `tenancy: host` and for platforms such as macOS. Hosts are billed
      # from allocation until release regardless of whether an instance is
      # running on them, so both operations are gated behind explicit config and
      # failures are fatal rather than warnings.
      #
      # Only hosts tagged `ManagedBy: Test Kitchen` are ever considered, so a
      # user's own dedicated hosts are never allocated to or released.
      #
      # This module expects its includer to provide `config`, `ec2` and the
      # Test Kitchen logging methods; it is mixed into {Kitchen::Driver::Ec2}.
      module DedicatedHosts
        # Whether any managed host has room for the configured instance type.
        #
        # @return [Boolean]
        def host_available?
          !hosts_with_capacity.empty?
        end

        # Managed hosts with room for the configured instance type.
        #
        # T-family hosts report no capacity information and may be
        # overprovisioned, so a host with no capacity block counts as available.
        #
        # @return [Array<Aws::EC2::Types::Host>]
        def hosts_with_capacity
          hosts_managed.select do |host|
            # T-instance hosts do not report available capacity and can be overprovisioned
            if host.available_capacity.nil?
              true
            else
              instance_capacity = host.available_capacity.available_instance_capacity
              capacity_for_type = instance_capacity.detect { |cap| cap.instance_type == config[:instance_type] }
              # A host that lists no capacity for this instance type cannot run
              # one, so treat a missing entry the same as zero rather than
              # raising on it.
              !capacity_for_type.nil? && capacity_for_type.available_capacity > 0
            end
          end
        end

        # Whether a host has no instances running on it.
        #
        # @param host [Aws::EC2::Types::Host] the host to inspect
        # @return [Boolean] true when the host can be released
        def host_unused?(host)
          host.instances.empty?
        end

        # Look a dedicated host up by ID.
        #
        # @param host_id [String] the host ID, e.g. "h-0123456789abcdef0"
        # @return [Aws::EC2::Types::Host, nil] the host, or nil when EC2 does
        #   not know it
        def host_for_id(host_id)
          ec2.client.describe_hosts(host_ids: [host_id]).hosts.first
        end

        # Available dedicated hosts that Test Kitchen allocated.
        #
        # Filtered on the `ManagedBy` tag so that hosts belonging to the user are
        # never touched, and on state so that hosts still being provisioned or
        # already released are ignored.
        #
        # @return [Array<Aws::EC2::Types::Host>]
        def hosts_managed
          response = ec2.client.describe_hosts(
            filter: [
              { name: "tag:ManagedBy", values: ["Test Kitchen"] },
            ]
          )

          response.hosts.select { |host| host.state == "available" }
        end

        # Allocate a new dedicated host for the configured instance type.
        #
        # A `.metal` size occupies a whole host, so it is allocated for that
        # exact type; every other size can share a host, so the whole instance
        # family is allocated and EC2 places instances within it.
        #
        # @return [String] the new host's ID
        # @note Terminates the process with `exit!` when allocation is not
        #   enabled or no availability zone is configured, since an allocated
        #   host costs money whether or not it is used.
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

        # Release a dedicated host.
        #
        # @param host_id [String] the host to release
        # @return [nil] when the host was released successfully
        # @note Terminates the process with `exit!` when the release fails, as a
        #   host that stays allocated keeps accruing charges silently.
        def deallocate_host(host_id)
          info("Deallocating dedicated host #{host_id}")

          response = ec2.client.release_hosts({ host_ids: [host_id] })
          return if response.unsuccessful.empty?

          warn "ERROR: Could not release dedicated host #{host_id}. Host may remain allocated and incur cost"
          exit!
        end

        # The family part of an instance type.
        #
        # @param instance_type [String] a type in "family.size" form, e.g. "m5.large"
        # @return [String] the family, e.g. "m5"
        def instance_family_from_type(instance_type)
          instance_type.split(".").first
        end

        # The size part of an instance type.
        #
        # @param instance_type [String] a type in "family.size" form, e.g. "m5.large"
        # @return [String] the size, e.g. "large"
        def instance_size_from_type(instance_type)
          instance_type.split(".").last
        end

        # Whether the user has opted in to allocating dedicated hosts.
        #
        # @return [Boolean]
        def allow_allocate_host?
          config[:allocate_dedicated_host]
        end

        # Whether the user has opted in to releasing dedicated hosts.
        #
        # @return [Boolean]
        def allow_deallocate_host?
          config[:deallocate_dedicated_host]
        end
      end
    end
  end
end
