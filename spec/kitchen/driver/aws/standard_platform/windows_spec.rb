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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Windows do
  it_behaves_like "a standard platform",
    registered_as: %w{windows},
    platform_name: "windows",
    username: "administrator",
    search_without_version: {
      "owner-alias" => "amazon",
      "name" => [
        "Windows_Server-*-RTM-English-*-Base-*",
        "Windows_Server-*-SP*-English-*-Base-*",
        "Windows_Server-*-R*_RTM-English-*-Base-*",
        "Windows_Server-*-R*_SP*-English-*-Base-*",
        "Windows_Server-*-English-Full-Base-*",
      ],
    },
    version: "2022",
    search_with_version: {
      "owner-alias" => "amazon",
      "name" => "Windows_Server-2022-English-Full-Base-*",
    },
    detects_image_named: "Windows_Server-2022-English-Full-Base-2024.08.14",
    detected_version: "2022rtm",
    ignores_image_named: "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  def name_filter_for(version)
    described_class.new(driver, "windows", version, nil).image_search["name"]
  end

  describe "#image_search" do
    # Modern releases are published under a single predictable name, so they get
    # one exact filter rather than the RTM/service-pack permutations older
    # releases need.
    it "uses a single Full-Base filter for 2016 and later" do
      expect(name_filter_for("2016")).to eq("Windows_Server-2016-English-Full-Base-*")
      expect(name_filter_for("2019")).to eq("Windows_Server-2019-English-Full-Base-*")
      expect(name_filter_for("2022")).to eq("Windows_Server-2022-English-Full-Base-*")
      expect(name_filter_for("2025")).to eq("Windows_Server-2025-English-Full-Base-*")
    end

    it "uses the Core container filter for the semi-annual channel releases" do
      expect(name_filter_for("1709")).to eq("Windows_Server-1709-English-Core-ContainersLatest-*")
      expect(name_filter_for("1803")).to eq("Windows_Server-1803-English-Core-ContainersLatest-*")
    end

    it "expands a bare major into both RTM and service pack filters" do
      expect(name_filter_for("2012")).to eq([
        "Windows_Server-2012-RTM-English-*-Base-*",
        "Windows_Server-2012-SP*-English-*-Base-*",
      ])
    end

    it "includes the revision when one is given" do
      expect(name_filter_for("2012r2")).to eq([
        "Windows_Server-2012-R2_RTM-English-*-Base-*",
        "Windows_Server-2012-R2_SP*-English-*-Base-*",
      ])
    end

    it "pins to a single filter when a service pack is given" do
      expect(name_filter_for("2012sp1")).to eq(["Windows_Server-2012-SP1-English-*-Base-*"])
      expect(name_filter_for("2012r2sp1")).to eq(["Windows_Server-2012-R2_SP1-English-*-Base-*"])
    end

    it "searches every naming scheme when no version is given" do
      expect(name_filter_for(nil)).to include(
        "Windows_Server-*-RTM-English-*-Base-*",
        "Windows_Server-*-R*_SP*-English-*-Base-*",
        "Windows_Server-*-English-Full-Base-*"
      )
    end

    it "accepts a windows-server- prefixed version" do
      expect(name_filter_for("server-2019")).to eq("Windows_Server-2019-English-Full-Base-*")
    end
  end

  describe ".from_image" do
    it "assumes RTM when the image name carries no service pack" do
      platform = described_class.from_image(driver, build_image(name: "Windows_Server-2016-English-Full-Base-2017.01.11"))
      expect(platform.version).to eq("2016rtm")
    end

    it "reads the revision out of the image name" do
      platform = described_class.from_image(
        driver,
        build_image(name: "Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.01.11")
      )
      expect(platform.version).to eq("2012r2rtm")
    end
  end

  describe "#sort_by_version" do
    # Windows versions do not sort correctly as floats -- "2012r2" is newer than
    # "2012" but older than "2016" -- so the platform decomposes them into
    # [major, revision, service_pack] tuples first.
    it "orders releases newest first, respecting revisions" do
      images = [
        build_image(name: "Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.01.11"),
        build_image(name: "Windows_Server-2022-English-Full-Base-2024.08.14"),
        build_image(name: "Windows_Server-2016-English-Full-Base-2017.01.11"),
        build_image(name: "Windows_Server-2019-English-Full-Base-2020.01.01"),
      ]

      sorted = described_class.new(driver, "windows", nil, nil).sort_by_version(images)

      expect(sorted.map(&:name)).to eq([
        "Windows_Server-2022-English-Full-Base-2024.08.14",
        "Windows_Server-2019-English-Full-Base-2020.01.01",
        "Windows_Server-2016-English-Full-Base-2017.01.11",
        "Windows_Server-2012-R2_RTM-English-64Bit-Base-2017.01.11",
      ])
    end
  end
end
