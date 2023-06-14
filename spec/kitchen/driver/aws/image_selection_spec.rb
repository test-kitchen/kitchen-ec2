#
# Copyright:: 2015-2018, Fletcher Nichol
# Copyright:: 2016-2018, Chef Software, Inc.
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

require "kitchen/driver/ec2"
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

describe "Default images for various platforms" do
  let(:driver) do
    Kitchen::Driver::Ec2.new(region: "us-west-2", aws_ssh_key_id: "foo", **config)
  end
  let(:config) { {} }
  let(:state_file) { {} }
  def new_instance(platform_name: "blarghle")
    Kitchen::Instance.new(
      driver: driver,
      suite: Kitchen::Suite.new(name: "suite-name"),
      platform: Kitchen::Platform.new(name: platform_name),
      provisioner: Kitchen::Provisioner::Dummy.new,
      transport: Kitchen::Transport::Dummy.new,
      verifier: Kitchen::Verifier::Dummy.new,
      state_file: Kitchen::StateFile.new("/nonexistent", "suite-name-#{platform_name}"),
      lifecycle_hooks: Kitchen::LifecycleHooks.new(config, state_file)
    )
  end

  PLATFORM_SEARCHES = {
    "alma" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS *"] },
    ],
    "alma-8" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS 8*"] },
    ],
    "alma-9" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS 9*"] },
    ],
    "alma-arm64" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS *"] },
      { name: "architecture", values: %w{arm64} },
    ],
    "alma-x86_64" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS *"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "alma-8-arm64" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS 8*"] },
      { name: "architecture", values: %w{arm64} },
    ],
    "alma-8-x86_64" => [
      { name: "owner-id", values: %w{764336703387} },
      { name: "name", values: ["AlmaLinux OS 8*"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "amazon" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*} },
    ],
    "amazon-x86_64" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*} },
      { name: "architecture", values: ["x86_64"] },
    ],
    "amazon-2016" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*-2016*} },
    ],
    "amazon-2017" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*-2017*} },
    ],
    "amazon-2016.09" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*-2016.09*} },
    ],
    "amazon-2017.03" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*-2017.03*} },
    ],
    "amazon-2017.03-x86_64" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn-ami-*-2017.03*} },
      { name: "architecture", values: ["x86_64"] },
    ],
    "amazon2" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn2-ami-hvm-2.0.*} },
    ],
    "amazon2-2018" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{amzn2-ami-hvm-2.0.2018*} },
    ],
    "amazon2023" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{al2023-ami-2023.0.*} },
    ],
    "amazon2023-x86_64" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{al2023-ami-2023.0.*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "amazon2023-arm64" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{al2023-ami-2023.0.*} },
      { name: "architecture", values: %w{arm64} },
    ],
    "amazon2023-20230222" => [
      { name: "owner-id", values: %w{137112412989} },
      { name: "name", values: %w{al2023-ami-2023.0.20230222*} },
    ],
    "centos" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: ["CentOS *", "CentOS-*-GA-*", "CentOS Linux *", "CentOS Stream *"] },
    ],
    "centos-8" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: ["CentOS 8*", "CentOS-8*-GA-*", "CentOS Linux 8*", "CentOS Stream 8*"] },
    ],
    "centos-7" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: ["CentOS 7*", "CentOS-7*-GA-*", "CentOS Linux 7*", "CentOS Stream 7*"] },
    ],
    "centos-x86_64" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: ["CentOS *", "CentOS-*-GA-*", "CentOS Linux *", "CentOS Stream *"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "centos-7-x86_64" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: ["CentOS 7*", "CentOS-7*-GA-*", "CentOS Linux 7*", "CentOS Stream 7*"] },
      { name: "architecture", values: %w{x86_64} },
    ],

    "debian" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-11-*} },
    ],
    "debian-13" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-13-*} },
    ],
    "debian-12" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-12-*} },
    ],
    "debian-11" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-11-*} },
    ],
    "debian-10" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-10-*} },
    ],
    "debian-9" => [
      { name: "owner-id", values: %w{379101102735} },
      { name: "name", values: %w{debian-stretch-*} },
    ],
    "debian-9.6" => [
      { name: "owner-id", values: %w{379101102735} },
      { name: "name", values: %w{debian-stretch-*} },
    ],
    "debian-x86_64" => [
      { name: "owner-id", values: %w{136693071363} },
      { name: "name", values: %w{debian-11-*} },
      { name: "architecture", values: %w{x86_64} },
    ],

    "rhel" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-*} },
    ],
    "rhel-6" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-6*} },
    ],
    "rhel-7.1" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-7.1*} },
    ],
    "rhel-x86_64" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "rhel-6-x86_64" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-6*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "rocky" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-*"] },
    ],
    "rocky-8" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-8-*"] },
    ],
    "rocky-9" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-9-*"] },
    ],
    "rocky-arm64" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-*"] },
      { name: "architecture", values: %w{arm64} },
    ],
    "rocky-x86_64" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-*"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "rocky-8-arm64" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-8-*"] },
      { name: "architecture", values: %w{arm64} },
    ],
    "rocky-8-x86_64" => [
      { name: "owner-id", values: %w{792107900819} },
      { name: "name", values: ["Rocky-8-*"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "el" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-*} },
    ],
    "el-6-x86_64" => [
      { name: "owner-id", values: %w{309956199498} },
      { name: "name", values: %w{RHEL-6*} },
      { name: "architecture", values: %w{x86_64} },
    ],

    "fedora" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: %w{Fedora-Cloud-Base-*} },
    ],
    "fedora-22" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: %w{Fedora-Cloud-Base-22-*} },
    ],
    "fedora-x86_64" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: %w{Fedora-Cloud-Base-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "fedora-22-x86_64" => [
      { name: "owner-id", values: %w{125523088429} },
      { name: "name", values: %w{Fedora-Cloud-Base-22-*} },
      { name: "architecture", values: %w{x86_64} },
    ],

    "freebsd" => [
      { name: "owner-id", values: %w{118940168514} },
      { name: "name", values: ["FreeBSD *-RELEASE*", "FreeBSD/EC2 *-RELEASE*"] },
    ],
    "freebsd-10" => [
      { name: "owner-id", values: %w{118940168514} },
      { name: "name", values: ["FreeBSD 10*-RELEASE*", "FreeBSD/EC2 10*-RELEASE*"] },
    ],
    "freebsd-10.1" => [
      { name: "owner-id", values: %w{118940168514} },
      { name: "name", values: ["FreeBSD 10.1*-RELEASE*", "FreeBSD/EC2 10.1*-RELEASE*"] },
    ],
    "freebsd-x86_64" => [
      { name: "owner-id", values: %w{118940168514} },
      { name: "name", values: ["FreeBSD *-RELEASE*", "FreeBSD/EC2 *-RELEASE*"] },
      { name: "architecture", values: %w{x86_64} },
    ],
    "freebsd-10-x86_64" => [
      { name: "owner-id", values: %w{118940168514} },
      { name: "name", values: ["FreeBSD 10*-RELEASE*", "FreeBSD/EC2 10*-RELEASE*"] },
      { name: "architecture", values: %w{x86_64} },
    ],

    "macos-12.5" => [
      { name: "owner-id", values: %w{100343932686} },
      { name: "name", values: %w{amzn-ec2-macos-12.5*} },
    ],
    "macos-12.6-arm64" => [
      { name: "owner-id", values: %w{100343932686} },
      { name: "name", values: %w{amzn-ec2-macos-12.6*} },
      { name: "architecture", values: %w{arm64_mac} },
    ],

    "ubuntu" => [
      { name: "owner-id", values: %w{099720109477} },
      { name: "name", values: %w{ubuntu/images/*/ubuntu-*-*} },
    ],
    "ubuntu-14" => [
      { name: "owner-id", values: %w{099720109477} },
      { name: "name", values: %w{ubuntu/images/*/ubuntu-*-14*} },
    ],
    "ubuntu-12.04" => [
      { name: "owner-id", values: %w{099720109477} },
      { name: "name", values: %w{ubuntu/images/*/ubuntu-*-12.04*} },
    ],
    "ubuntu-x86_64" => [
      { name: "owner-id", values: %w{099720109477} },
      { name: "name", values: %w{ubuntu/images/*/ubuntu-*-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "ubuntu-14-x86_64" => [
      { name: "owner-id", values: %w{099720109477} },
      { name: "name", values: %w{ubuntu/images/*/ubuntu-*-14*} },
      { name: "architecture", values: %w{x86_64} },
    ],

    "windows" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
    ],
    "windows-2008" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2008-RTM-English-*-Base-*
        Windows_Server-2008-SP*-English-*-Base-*} },
    ],
    "windows-2012" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-RTM-English-*-Base-*
        Windows_Server-2012-SP*-English-*-Base-*} },
    ],
    "windows-2012r2" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
    ],
    "windows-2012sp1" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-SP1-English-*-Base-*} },
    ],
    "windows-2012rtm" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-RTM-English-*-Base-*} },
    ],
    "windows-2012r2sp1" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-R2_SP1-English-*-Base-*} },
    ],
    "windows-2012r2rtm" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*} },
    ],
    "windows-x86_64" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "windows-2012r2-x86_64" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "windows-server" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
    ],
    "windows-server-2012r2-x86_64" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
      { name: "architecture", values: %w{x86_64} },
    ],
    "windows-2016" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2016-English-Full-Base-*} },
    ],
    "windows-2019" => [
      { name: "owner-alias", values: %w{amazon} },
      { name: "name", values: %w{
        Windows_Server-2019-English-Full-Base-*} },
    ],
  }.freeze

  describe "Platform defaults" do
    PLATFORM_SEARCHES.each do |platform_name, filters|
      context "when platform is #{platform_name}" do
        let(:image) { FakeImage.new(name: platform_name.split("-", 2)[0]) }

        it "searches for #{filters} and uses the resulting image" do
          expect(driver.ec2.resource)
            .to receive(:images).with(filters: filters).and_return([image])
          expect(driver.ec2.resource)
            .to receive(:image).with(image.id).and_return(image)

          instance = new_instance(platform_name: platform_name)
          expect(instance.driver.instance_generator.ec2_instance_data[:image_id])
            .to eq image.id
        end
      end
    end
  end

  context "when image_search is provided" do
    let(:image) { FakeImage.new(name: "ubuntu") }
    let(:config) { { image_search: { name: "SuperImage" } } }

    context "and platform.name is a well known platform name" do
      it "searches for an image id without using the standard filters" do
        expect(driver.ec2.resource)
          .to receive(:images)
          .with(filters: [{ name: "name", values: %w{SuperImage} }])
          .and_return([image])
        expect(driver.ec2.resource)
          .to receive(:image).with(image.id).and_return(image)

        instance = new_instance(platform_name: "ubuntu")
        expect(instance.driver.instance_generator.ec2_instance_data[:image_id])
          .to eq image.id
      end
    end

    context "and platform.name is not a well known platform name" do
      let(:image) { FakeImage.new(name: "ubuntu") }
      it "does not search for (or find) an image, and informs the user they need to set image_id" do
        expect(driver.ec2.resource)
          .to receive(:images)
          .with(filters: [{ name: "name", values: %w{SuperImage} }])
          .and_return([image])
        expect(driver.ec2.resource)
          .to receive(:image).with(image.id).and_return(image)

        instance = new_instance(platform_name: "blarghle")
        expect(instance.driver.instance_generator.ec2_instance_data[:image_id]).to eq image.id
      end
    end
  end
end
