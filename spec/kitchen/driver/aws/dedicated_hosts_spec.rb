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

require "kitchen/driver/ec2"

# The mixin is exercised through the driver that includes it rather than
# through a synthetic host class, because every method depends on the driver
# for `config`, `ec2` and logging.
RSpec.describe Kitchen::Driver::Mixins::DedicatedHosts do
  subject(:driver) do
    build_driver(instance_type: "m5.large", availability_zone: "us-west-2a", **config)
  end

  let(:config) { {} }
  let(:ec2_client) { stub_ec2_client }

  before do
    allow(driver).to receive(:ec2).and_return(stub_aws_client(client: ec2_client))
  end

  # Several methods call `exit!`, which halts the process outright and cannot be
  # rescued. Stubbing it to raise SystemExit preserves the "execution stops
  # here" semantics while leaving the example able to assert on it.
  def stub_exit!
    allow(driver).to receive(:exit!).and_raise(SystemExit)
  end

  def host(host_id: "h-0123456789abcdef0", state: "available", instance_types: { "m5.large" => 2 }, instances: [])
    {
      host_id: host_id,
      state: state,
      instances: instances,
      available_capacity: if instance_types.nil?
                            nil
                          else
                            {
                              available_instance_capacity: instance_types.map do |type, capacity|
                                { instance_type: type, available_capacity: capacity }
                              end,
                            }
                          end,
    }
  end

  describe "#hosts_managed" do
    let(:ec2_client) do
      stub_ec2_client(
        describe_hosts: {
          hosts: [
            host(host_id: "h-available", state: "available"),
            host(host_id: "h-pending", state: "pending"),
            host(host_id: "h-released", state: "released"),
          ],
        }
      )
    end

    it "returns only hosts in the available state" do
      expect(driver.hosts_managed.map(&:host_id)).to eq(%w{h-available})
    end

    # Test Kitchen only ever manages hosts it tagged itself, so that a user's
    # own dedicated hosts are never allocated to or released by kitchen.
    it "asks only for hosts tagged as managed by Test Kitchen" do
      driver.hosts_managed

      expect(request_params_for(ec2_client, :describe_hosts)[:filter]).to eq([
        { name: "tag:ManagedBy", values: ["Test Kitchen"] },
      ])
    end
  end

  describe "#hosts_with_capacity" do
    context "when a host has room for the configured instance type" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(instance_types: { "m5.large" => 3 })] }) }

      it "includes the host" do
        expect(driver.hosts_with_capacity.size).to eq(1)
      end
    end

    context "when a host is full" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(instance_types: { "m5.large" => 0 })] }) }

      it "excludes the host" do
        expect(driver.hosts_with_capacity).to be_empty
      end
    end

    # T-family hosts report no capacity at all and may be overprovisioned, so
    # a missing capacity block is treated as "room available" rather than full.
    context "when a host reports no capacity information" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(instance_types: nil)] }) }

      it "includes the host" do
        expect(driver.hosts_with_capacity.size).to eq(1)
      end
    end

    context "when a host reports capacity for other instance types only" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(instance_types: { "c5.large" => 4 })] }) }

      # A host that lists capacity for other sizes but not this one cannot run
      # the configured instance type, so it is excluded rather than raising.
      it "excludes the host" do
        expect(driver.hosts_with_capacity).to be_empty
      end
    end
  end

  describe "#host_available?" do
    context "when a host has capacity" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host] }) }

      it "is true" do
        expect(driver.host_available?).to be(true)
      end
    end

    context "when no host has capacity" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [] }) }

      it "is false" do
        expect(driver.host_available?).to be(false)
      end
    end
  end

  describe "#host_unused?" do
    let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(instances: instances)] }) }

    context "with no instances on the host" do
      let(:instances) { [] }

      it "is true" do
        expect(driver.host_unused?(driver.hosts_managed.first)).to be(true)
      end
    end

    context "with an instance running on the host" do
      let(:instances) { [{ instance_id: "i-0123456789abcdef0" }] }

      it "is false" do
        expect(driver.host_unused?(driver.hosts_managed.first)).to be(false)
      end
    end
  end

  describe "#host_for_id" do
    let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [host(host_id: "h-wanted")] }) }

    it "looks the host up by ID" do
      driver.host_for_id("h-wanted")
      expect(request_params_for(ec2_client, :describe_hosts)[:host_ids]).to eq(%w{h-wanted})
    end

    it "returns the host" do
      host = driver.host_for_id("h-wanted")

      expect(host).to be_a(::Aws::EC2::Types::Host)
      expect(host.host_id).to eq("h-wanted")
    end

    context "when EC2 does not know the host" do
      let(:ec2_client) { stub_ec2_client(describe_hosts: { hosts: [] }) }

      it "returns nil" do
        expect(driver.host_for_id("h-missing")).to be_nil
      end
    end
  end

  describe "#instance_family_from_type" do
    it "returns the part before the dot" do
      expect(driver.instance_family_from_type("m5.large")).to eq("m5")
      expect(driver.instance_family_from_type("mac1.metal")).to eq("mac1")
    end
  end

  describe "#instance_size_from_type" do
    it "returns the part after the dot" do
      expect(driver.instance_size_from_type("m5.large")).to eq("large")
      expect(driver.instance_size_from_type("mac1.metal")).to eq("metal")
    end
  end

  describe "#metal_instance_type?" do
    it "is true for a bare .metal size" do
      expect(driver.metal_instance_type?("mac1.metal")).to be(true)
      expect(driver.metal_instance_type?("c5.metal")).to be(true)
    end

    # Newer families expose several bare-metal sizes on one family, named
    # ".metal-24xl" and so on rather than a plain ".metal".
    it "is true for a sized .metal variant" do
      expect(driver.metal_instance_type?("m7i.metal-24xl")).to be(true)
      expect(driver.metal_instance_type?("m8g.metal-48xl")).to be(true)
    end

    it "is false for a virtualized size" do
      expect(driver.metal_instance_type?("m5.large")).to be(false)
      expect(driver.metal_instance_type?("u7i-12tb.224xlarge")).to be(false)
    end
  end

  describe "#allow_allocate_host?" do
    context "when allocate_dedicated_host is set" do
      let(:config) { { allocate_dedicated_host: true } }

      it "is true" do
        expect(driver.allow_allocate_host?).to be(true)
      end
    end

    it "is false by default" do
      expect(driver.allow_allocate_host?).to be_falsey
    end
  end

  describe "#allow_deallocate_host?" do
    context "when deallocate_dedicated_host is set" do
      let(:config) { { deallocate_dedicated_host: true } }

      it "is true" do
        expect(driver.allow_deallocate_host?).to be(true)
      end
    end

    it "is false by default" do
      expect(driver.allow_deallocate_host?).to be_falsey
    end
  end

  describe "#allocate_host" do
    let(:config) { { allocate_dedicated_host: true } }
    let(:ec2_client) { stub_ec2_client(allocate_hosts: { host_ids: %w{h-newlyallocated} }) }

    it "returns the ID of the newly allocated host" do
      expect(driver.allocate_host).to eq("h-newlyallocated")
    end

    it "tags the host as managed by Test Kitchen so it can be found again" do
      driver.allocate_host

      expect(request_params_for(ec2_client, :allocate_hosts)[:tag_specifications]).to eq([
        {
          resource_type: "dedicated-host",
          tags: [{ key: "ManagedBy", value: "Test Kitchen" }],
        },
      ])
    end

    it "allocates a single auto-placement host in the configured zone" do
      driver.allocate_host

      expect(request_params_for(ec2_client, :allocate_hosts)).to include(
        availability_zone: "us-west-2a",
        quantity: 1,
        auto_placement: "on"
      )
    end

    # A .metal host serves exactly one instance, so it is allocated for that
    # specific type. Every other size can host several instances, so the whole
    # family is allocated and EC2 places instances within it.
    it "allocates by instance family for a shared host" do
      driver.allocate_host

      params = request_params_for(ec2_client, :allocate_hosts)
      expect(params[:instance_family]).to eq("m5")
      expect(params).not_to have_key(:instance_type)
    end

    context "with a .metal instance type" do
      subject(:driver) do
        build_driver(instance_type: "mac1.metal", availability_zone: "us-west-2a", **config)
      end

      it "allocates by instance type" do
        driver.allocate_host

        params = request_params_for(ec2_client, :allocate_hosts)
        expect(params[:instance_type]).to eq("mac1.metal")
        expect(params).not_to have_key(:instance_family)
      end
    end

    context "with a sized .metal instance type" do
      subject(:driver) do
        build_driver(instance_type: "m7i.metal-24xl", availability_zone: "us-west-2a", **config)
      end

      it "allocates by instance type" do
        driver.allocate_host

        params = request_params_for(ec2_client, :allocate_hosts)
        expect(params[:instance_type]).to eq("m7i.metal-24xl")
        expect(params).not_to have_key(:instance_family)
      end
    end

    context "when host allocation has not been enabled" do
      let(:config) { { allocate_dedicated_host: false } }

      it "refuses to allocate" do
        stub_exit!
        expect { driver.allocate_host }.to raise_error(SystemExit)
      end

      it "explains which setting is missing" do
        stub_exit!
        expect { driver.allocate_host }.to raise_error(SystemExit)
        expect(logged_output.string).to match(/TK_ALLOCATE_DEDICATED_HOST/)
      end
    end

    context "when no availability zone is configured" do
      subject(:driver) { build_driver(instance_type: "m5.large", allocate_dedicated_host: true) }

      # A dedicated host exists in one specific zone, so there is no sensible
      # default to fall back on.
      it "refuses to allocate" do
        stub_exit!
        expect { driver.allocate_host }.to raise_error(SystemExit)
        expect(logged_output.string).to match(/availability_zone/)
      end
    end
  end

  describe "#deallocate_host" do
    let(:ec2_client) { stub_ec2_client(release_hosts: { successful: %w{h-old}, unsuccessful: [] }) }

    it "releases the host" do
      driver.deallocate_host("h-old")
      expect(request_params_for(ec2_client, :release_hosts)[:host_ids]).to eq(%w{h-old})
    end

    it "returns nil when the release succeeds" do
      expect(driver.deallocate_host("h-old")).to be_nil
    end

    context "when the release fails" do
      let(:ec2_client) do
        stub_ec2_client(
          release_hosts: {
            successful: [],
            unsuccessful: [{ resource_id: "h-old", error: { code: "InvalidHostId", message: "nope" } }],
          }
        )
      end

      # A host that fails to release keeps billing, so this is loud and fatal
      # rather than a warning the user might scroll past.
      it "aborts and warns that the host may still cost money" do
        stub_exit!
        expect { driver.deallocate_host("h-old") }.to raise_error(SystemExit)
        expect(logged_output.string).to match(/may remain allocated and incur cost/)
      end
    end
  end
end
