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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform do
  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  describe ".parse_platform_string" do
    it "parses a bare platform name" do
      expect(described_class.parse_platform_string("ubuntu")).to eq(["ubuntu", nil, nil])
    end

    it "parses a platform and version" do
      expect(described_class.parse_platform_string("ubuntu-22.04")).to eq(["ubuntu", "22.04", nil])
    end

    it "parses a platform, version and architecture" do
      expect(described_class.parse_platform_string("ubuntu-22.04-x86_64")).to eq(%w{ubuntu 22.04 x86_64})
    end

    it "parses a platform and architecture with no version" do
      expect(described_class.parse_platform_string("debian-arm64")).to eq(["debian", nil, "arm64"])
    end

    it "keeps multi-part versions intact" do
      expect(described_class.parse_platform_string("windows-server-2022-x86_64"))
        .to eq(%w{windows server-2022 x86_64})
    end

    # Only the three values in SUPPORTED_ARCHITECTURES are recognized as an
    # architecture. Anything else stays part of the version, which is how a
    # typo surfaces as "no such version" rather than being silently dropped.
    it "treats an unrecognized architecture as part of the version" do
      expect(described_class.parse_platform_string("ubuntu-22.04-powerpc"))
        .to eq(["ubuntu", "22.04-powerpc", nil])
    end

    it "recognizes every supported architecture" do
      described_class::SUPPORTED_ARCHITECTURES.each do |architecture|
        expect(described_class.parse_platform_string("ubuntu-22.04-#{architecture}"))
          .to eq(["ubuntu", "22.04", architecture])
      end
    end
  end

  describe ".from_platform_string" do
    it "builds the platform registered under the given name" do
      platform = described_class.from_platform_string(driver, "ubuntu-22.04-x86_64")

      expect(platform).to be_an_instance_of(described_class::Ubuntu)
      expect(platform.name).to eq("ubuntu")
      expect(platform.version).to eq("22.04")
      expect(platform.architecture).to eq("x86_64")
    end

    it "returns nil for an unregistered platform name" do
      expect(described_class.from_platform_string(driver, "plan9")).to be_nil
    end

    it "returns nil for an empty string" do
      expect(described_class.from_platform_string(driver, "")).to be_nil
    end
  end

  describe ".platforms" do
    it "holds every platform that registered itself" do
      expect(described_class.platforms).to include(
        "ubuntu", "debian", "centos", "rhel", "el", "windows", "fedora",
        "freebsd", "macos", "amazon", "amazon2", "amazon2023", "alma",
        "almalinux", "rocky", "rockylinux"
      )
    end
  end

  describe ".from_image" do
    it "dispatches to the platform that claims the image" do
      image = build_image(name: "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801")
      expect(described_class.from_image(driver, image)).to be_an_instance_of(described_class::Ubuntu)
    end

    it "returns nil when no platform claims the image" do
      expect(described_class.from_image(driver, build_image(name: "some-unbranded-image"))).to be_nil
    end
  end

  describe "#find_image" do
    subject(:platform) { described_class::Ubuntu.new(driver, "ubuntu", nil, nil) }

    let(:resource) { stub_image_resource(images) }
    let(:images) { [build_image(name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-1")] }

    before do
      allow(driver).to receive(:debug)
      allow(driver).to receive(:error)
      allow(driver).to receive(:image_info).and_return("")
      allow(driver).to receive(:ec2).and_return(stub_aws_client(client: resource.client, resource: resource))
    end

    it "returns the ID of the best matching image" do
      expect(platform.find_image("name" => "ubuntu-*")).to eq(images.first.id)
    end

    # The platform's search hash is keyed by filter name; EC2 wants a list of
    # {name:, values:} pairs, with every value a string.
    it "converts the search hash into EC2 filter pairs" do
      platform.find_image("owner-id" => "099720109477", "name" => %w{ubuntu-a ubuntu-b})

      expect(request_params_for(resource.client, :describe_images)[:filters]).to eq([
        { name: "owner-id", values: %w{099720109477} },
        { name: "name", values: %w{ubuntu-a ubuntu-b} },
      ])
    end

    it "stringifies non-string filter values" do
      platform.find_image("architecture" => :x86_64)

      expect(request_params_for(resource.client, :describe_images)[:filters]).to eq([
        { name: "architecture", values: %w{x86_64} },
      ])
    end

    context "when the search matches nothing" do
      let(:images) { [] }

      it "returns nil" do
        expect(platform.find_image("name" => "nope-*")).to be_nil
      end

      it "reports the empty result to the user" do
        platform.find_image("name" => "nope-*")
        expect(driver).to have_received(:error).with(/Search returned 0 images/)
      end
    end
  end

  # `find_image` ranks candidates through a chain of preferences. These are
  # asserted through the public entry point rather than the private sorter, and
  # each example varies exactly one attribute so the preference under test is
  # the only thing that can decide the winner.
  describe "image ranking" do
    subject(:platform) { described_class::Ubuntu.new(driver, "ubuntu", nil, nil) }

    let(:resource) { stub_image_resource(images) }

    before do
      allow(driver).to receive(:debug)
      allow(driver).to receive(:error)
      allow(driver).to receive(:image_info).and_return("")
      allow(driver).to receive(:ec2).and_return(stub_aws_client(client: resource.client, resource: resource))
    end

    def winner
      images.find { |image| image.id == platform.find_image("name" => "ubuntu-*") }
    end

    context "with images differing only by creation date" do
      let(:images) do
        [
          build_image(name: "ubuntu-22.04-older", creation_date: "2024-01-01T00:00:00.000Z"),
          build_image(name: "ubuntu-22.04-newer", creation_date: "2024-06-01T00:00:00.000Z"),
        ]
      end

      it "prefers the most recently created image" do
        expect(winner.name).to eq("ubuntu-22.04-newer")
      end
    end

    context "with images differing only by architecture" do
      let(:images) do
        [
          build_image(name: "ubuntu-22.04-i386", architecture: "i386"),
          build_image(name: "ubuntu-22.04-x86-64", architecture: "x86_64"),
        ]
      end

      it "prefers x86_64 over i386" do
        expect(winner.name).to eq("ubuntu-22.04-x86-64")
      end
    end

    context "with images differing only by root volume type" do
      let(:images) do
        [
          build_image(name: "ubuntu-22.04-magnetic", volume_type: "standard"),
          build_image(name: "ubuntu-22.04-ssd", volume_type: "gp3"),
        ]
      end

      it "prefers an SSD-backed root volume" do
        expect(winner.name).to eq("ubuntu-22.04-ssd")
      end
    end

    context "with images differing only by root device type" do
      let(:images) do
        [
          build_image(name: "ubuntu-22.04-instance-store", root_device_type: "instance-store"),
          build_image(name: "ubuntu-22.04-ebs", root_device_type: "ebs"),
        ]
      end

      it "prefers EBS over instance store" do
        expect(winner.name).to eq("ubuntu-22.04-ebs")
      end
    end

    context "with images differing only by virtualization type" do
      let(:images) do
        [
          build_image(name: "ubuntu-22.04-paravirtual", virtualization_type: "paravirtual"),
          build_image(name: "ubuntu-22.04-hvm", virtualization_type: "hvm"),
        ]
      end

      it "prefers HVM over paravirtual" do
        expect(winner.name).to eq("ubuntu-22.04-hvm")
      end
    end

    context "with a newer version that loses on every other preference" do
      let(:images) do
        [
          build_image(
            name: "ubuntu-24.04-server",
            architecture: "i386",
            virtualization_type: "paravirtual",
            root_device_type: "instance-store",
            volume_type: "standard",
            creation_date: "2020-01-01T00:00:00.000Z"
          ),
          build_image(
            name: "ubuntu-22.04-server",
            architecture: "x86_64",
            virtualization_type: "hvm",
            root_device_type: "ebs",
            volume_type: "gp3",
            creation_date: "2024-01-01T00:00:00.000Z"
          ),
        ]
      end

      # Version is applied last and therefore dominates: a 24.04 image wins even
      # when it is older, paravirtual, i386 and instance-store backed.
      it "still prefers the newer version" do
        expect(winner.name).to eq("ubuntu-24.04-server")
      end
    end
  end
end
