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

# The contract every `StandardPlatform` subclass has to satisfy.
#
# Each subclass does the same four jobs -- register itself under one or more
# names, report a default SSH username, build an AMI search filter, and detect
# itself from an image name -- so those are asserted once here and driven from
# a small table in each platform's own spec file.
#
# Behavior genuinely unique to a platform (CentOS's version-dependent username,
# RHEL's beta shunning, Windows' version arithmetic) stays in that platform's
# spec file rather than being bolted onto this contract.
#
# @param params [Hash]
# @option params [Array<String>] :registered_as names the class registers under
# @option params [String] :platform_name the canonical name instances report
# @option params [String] :username expected default SSH username
# @option params [Hash] :search_without_version expected filter with no version
# @option params [String] :version a version string to search for
# @option params [Hash] :search_with_version expected filter for that version
# @option params [String] :detects_image_named an AMI name this platform owns
# @option params [String, nil] :detected_version version parsed from that name
# @option params [String] :ignores_image_named an AMI name it must not claim
RSpec.shared_examples "a standard platform" do |params|
  let(:driver) { instance_double(Kitchen::Driver::Ec2) }

  # Build an instance of the platform under test. Subclasses may rewrite the
  # name they were constructed with (El maps "el" onto "rhel"), so this passes
  # the canonical name through and lets the class decide.
  def build_platform(driver, name, version, architecture)
    described_class.new(driver, name, version, architecture)
  end

  describe "registration" do
    it "registers itself under each of its names" do
      params.fetch(:registered_as).each do |name|
        expect(Kitchen::Driver::Aws::StandardPlatform.platforms[name]).to eq(described_class)
      end
    end

    it "is built by from_platform_string for each of its names" do
      params.fetch(:registered_as).each do |name|
        platform = Kitchen::Driver::Aws::StandardPlatform.from_platform_string(driver, name)
        expect(platform).to be_an_instance_of(described_class)
      end
    end
  end

  describe "#username" do
    it "returns the platform's default SSH username" do
      platform = build_platform(driver, params.fetch(:platform_name), nil, nil)
      expect(platform.username).to eq(params.fetch(:username))
    end
  end

  describe "#image_search" do
    it "searches for the newest image when no version is given" do
      platform = build_platform(driver, params.fetch(:platform_name), nil, nil)
      expect(platform.image_search).to eq(params.fetch(:search_without_version))
    end

    it "narrows the search when a version is given" do
      platform = build_platform(driver, params.fetch(:platform_name), params.fetch(:version), nil)
      expect(platform.image_search).to eq(params.fetch(:search_with_version))
    end

    it "adds an architecture filter when an architecture is given" do
      platform = build_platform(driver, params.fetch(:platform_name), nil, "arm64")
      # macOS is the exception: it maps arm64 onto EC2's "arm64_mac" value.
      expected = params.fetch(:architecture_filter, "arm64")
      expect(platform.image_search).to include("architecture" => expected)
    end

    it "omits the architecture filter when no architecture is given" do
      platform = build_platform(driver, params.fetch(:platform_name), nil, nil)
      expect(platform.image_search).not_to have_key("architecture")
    end
  end

  describe ".from_image" do
    it "detects the platform from a matching image name" do
      image = build_image(name: params.fetch(:detects_image_named))
      platform = described_class.from_image(driver, image)

      expect(platform).to be_an_instance_of(described_class)
      expect(platform.name).to eq(params.fetch(:platform_name))
      expect(platform.version).to eq(params.fetch(:detected_version))
    end

    it "carries the image's architecture onto the detected platform" do
      image = build_image(name: params.fetch(:detects_image_named), architecture: "arm64")
      expect(described_class.from_image(driver, image).architecture).to eq("arm64")
    end

    it "returns nil for an image belonging to another platform" do
      image = build_image(name: params.fetch(:ignores_image_named))
      expect(described_class.from_image(driver, image)).to be_nil
    end
  end

  describe "#to_s" do
    it "describes the platform, version and architecture" do
      platform = build_platform(driver, params.fetch(:platform_name), params.fetch(:version), "x86_64")
      expect(platform.to_s).to eq("#{params.fetch(:platform_name)} #{params.fetch(:version)} x86_64")
    end

    it "omits version and architecture when they are unknown" do
      platform = build_platform(driver, params.fetch(:platform_name), nil, nil)
      expect(platform.to_s).to eq(params.fetch(:platform_name))
    end
  end
end
