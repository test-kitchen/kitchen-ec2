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

RSpec.describe Kitchen::Driver::Aws::StandardPlatform::Debian do
  it_behaves_like "a standard platform",
    registered_as: %w{debian},
    platform_name: "debian",
    username: "admin",
    search_without_version: { "owner-id" => "136693071363", "name" => "debian-13-*" },
    version: "12",
    search_with_version: { "owner-id" => "136693071363", "name" => "debian-12-*" },
    detects_image_named: "debian-12-amd64-20240717-1811",
    detected_version: "12",
    ignores_image_named: "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801"

  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  def platform_for(version)
    described_class.new(driver, "debian", version, nil)
  end

  # `#codename` warns on stderr when it truncates a version. Swallow that here
  # so the suite stays quiet; the warning itself is asserted below.
  def codename_for(version)
    original = $stderr
    $stderr = StringIO.new
    platform_for(version).codename
  ensure
    $stderr = original
  end

  describe "#codename" do
    it "maps a major version onto its Debian codename" do
      expect(codename_for("11")).to eq("bullseye")
      expect(codename_for("12")).to eq("bookworm")
      expect(codename_for("13")).to eq("trixie")
    end

    it "falls back to the newest known codename when no version is given" do
      expect(codename_for(nil)).to eq("trixie")
    end

    # A bare major version resolves exactly, so there is nothing to warn about.
    # It used to warn for any version longer than one character, producing the
    # nonsensical "version 12 specified, but searching for 12 instead".
    it "does not warn for a bare major version" do
      expect { platform_for("9").codename }.not_to output.to_stderr
      expect { platform_for("12").codename }.not_to output.to_stderr
      expect { platform_for("13").codename }.not_to output.to_stderr
    end

    it "does not warn when no version was given" do
      expect { platform_for(nil).codename }.not_to output.to_stderr
    end

    # A minor version cannot select a codename, so it is truncated -- and that
    # loss of precision is worth telling the user about.
    it "warns when a more precise version is truncated" do
      expect { platform_for("12.5").codename }
        .to output(/WARN: Debian version 12\.5 specified, but searching for 12 instead/).to_stderr
    end

    it "still resolves the codename after truncating" do
      expect(codename_for("12.5")).to eq("bookworm")
    end
  end

  describe "#image_search" do
    # Debian moved to a new AWS account for the 10 "buster" release, and the
    # naming scheme changed with it: releases from 10 onwards are searched for
    # by number, earlier ones by codename.
    it "searches by version number under the current owner from 10 onwards" do
      expect(platform_for("12").image_search).to eq(
        "owner-id" => "136693071363", "name" => "debian-12-*"
      )
    end

    it "searches by codename under the legacy owner below 10" do
      expect(platform_for("9").image_search).to eq(
        "owner-id" => "379101102735", "name" => "debian-stretch-*"
      )
    end

    it "defaults to the newest known release when no version is given" do
      expect(platform_for(nil).image_search).to eq(
        "owner-id" => "136693071363", "name" => "debian-13-*"
      )
    end
  end

  describe ".from_image" do
    it "detects a version from a numbered image name" do
      platform = described_class.from_image(driver, build_image(name: "debian-12-amd64-20240717-1811"))
      expect(platform.version).to eq("12")
    end

    it "resolves a codename in the image name back to its version number" do
      platform = described_class.from_image(driver, build_image(name: "debian-bookworm-hvm-x86_64-gp3-2023"))
      expect(platform.version).to eq("12")
    end

    it "resolves a legacy codename too" do
      platform = described_class.from_image(driver, build_image(name: "debian-stretch-hvm-x86_64-gp2-2019"))
      expect(platform.version).to eq("9")
    end

    # Both detection paths have to agree on type: callers compare and display
    # these without knowing whether the name carried a number or a codename.
    it "reports a String version whichever form the image name used" do
      numbered = described_class.from_image(driver, build_image(name: "debian-12-amd64-20240717-1811"))
      codenamed = described_class.from_image(driver, build_image(name: "debian-bookworm-hvm-x86_64-gp3-2023"))

      expect(numbered.version).to be_a(String)
      expect(codenamed.version).to be_a(String)
      expect(codenamed.version).to eq(numbered.version)
    end
  end
end
