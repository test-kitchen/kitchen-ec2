require "kitchen/driver/ec2"
require "kitchen/provisioner/dummy"
require "kitchen/transport/dummy"
require "kitchen/verifier/dummy"

describe "Default images for various platforms" do

  class FakeImage
    def self.next_ami
      @n ||= 0
      @n += 1
      [sprintf("ami-%08x", @n), Time.now + @n]
    end

    def initialize(name: "foo")
      @id, @creation_date = FakeImage.next_ami
      @name = name
      @creation_date = @creation_date.strftime("%F %T")
      @architecture = :x86_64
      @volume_type = "gp2"
      @root_device_type = "ebs"
      @virtualization_type = "hvm"
      @root_device_name = "root"
      @device_name = "root"
    end
    attr_reader :id
    attr_reader :name
    attr_reader :creation_date
    attr_reader :architecture
    attr_reader :volume_type
    attr_reader :root_device_type
    attr_reader :virtualization_type
    attr_reader :root_device_name
    attr_reader :device_name

    def block_device_mappings
      [self]
    end

    def ebs
      self
    end
  end

  let(:driver) do
    Kitchen::Driver::Ec2.new(:region => "us-west-2", :aws_ssh_key_id => "foo", **config)
  end
  let(:config) { {} }
  def new_instance(platform_name: "blarghle")
    Kitchen::Instance.new(
      :driver => driver,
      :suite => Kitchen::Suite.new(:name => "suite-name"),
      :platform => Kitchen::Platform.new(:name => platform_name),
      :provisioner => Kitchen::Provisioner::Dummy.new,
      :transport => Kitchen::Transport::Dummy.new,
      :verifier => Kitchen::Verifier::Dummy.new,
      :state_file => Kitchen::StateFile.new("/nonexistent", "suite-name-#{platform_name}")
    )
  end

  PLATFORM_SEARCHES = {
    "centos" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux *", "CentOS-*-GA-*"] },
    ],
    "centos-7" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux 7*", "CentOS-7*-GA-*"] },
    ],
    "centos-6" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux 6*", "CentOS-6*-GA-*"] },
    ],
    "centos-6.3" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux 6.3*", "CentOS-6.3*-GA-*"] },
    ],
    "centos-x86_64" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux *", "CentOS-*-GA-*"] },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "centos-6.3-x86_64" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux 6.3*", "CentOS-6.3*-GA-*"] },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "centos-7-x86_64" => [
      { :name => "owner-alias", :values => %w{aws-marketplace} },
      { :name => "name", :values => ["CentOS Linux 7*", "CentOS-7*-GA-*"] },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "debian" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-jessie-*} },
    ],
    "debian-8" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-jessie-*} },
    ],
    "debian-7" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-wheezy-*} },
    ],
    "debian-6" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-squeeze-*} },
    ],
    "debian-x86_64" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-jessie-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "debian-6-x86_64" => [
      { :name => "owner-id", :values => %w{379101102735} },
      { :name => "name", :values => %w{debian-squeeze-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "rhel" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-*} },
    ],
    "rhel-6" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-6*} },
    ],
    "rhel-7.1" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-7.1*} },
    ],
    "rhel-x86_64" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "rhel-6-x86_64" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-6*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "el" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-*} },
    ],
    "el-6-x86_64" => [
      { :name => "owner-id", :values => %w{309956199498} },
      { :name => "name", :values => %w{RHEL-6*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "fedora" => [
      { :name => "owner-id", :values => %w{125523088429} },
      { :name => "name", :values => %w{Fedora-Cloud-Base-*} },
    ],
    "fedora-22" => [
      { :name => "owner-id", :values => %w{125523088429} },
      { :name => "name", :values => %w{Fedora-Cloud-Base-22-*} },
    ],
    "fedora-x86_64" => [
      { :name => "owner-id", :values => %w{125523088429} },
      { :name => "name", :values => %w{Fedora-Cloud-Base-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "fedora-22-x86_64" => [
      { :name => "owner-id", :values => %w{125523088429} },
      { :name => "name", :values => %w{Fedora-Cloud-Base-22-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "freebsd" => [
      { :name => "owner-id", :values => %w{118940168514} },
      { :name => "name", :values => ["FreeBSD *-RELEASE*", "FreeBSD/EC2 *-RELEASE*"] },
    ],
    "freebsd-10" => [
      { :name => "owner-id", :values => %w{118940168514} },
      { :name => "name", :values => ["FreeBSD 10*-RELEASE*", "FreeBSD/EC2 10*-RELEASE*"] },
    ],
    "freebsd-10.1" => [
      { :name => "owner-id", :values => %w{118940168514} },
      { :name => "name", :values => ["FreeBSD 10.1*-RELEASE*", "FreeBSD/EC2 10.1*-RELEASE*"] },
    ],
    "freebsd-x86_64" => [
      { :name => "owner-id", :values => %w{118940168514} },
      { :name => "name", :values => ["FreeBSD *-RELEASE*", "FreeBSD/EC2 *-RELEASE*"] },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "freebsd-10-x86_64" => [
      { :name => "owner-id", :values => %w{118940168514} },
      { :name => "name", :values => ["FreeBSD 10*-RELEASE*", "FreeBSD/EC2 10*-RELEASE*"] },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "ubuntu" => [
      { :name => "owner-id", :values => %w{099720109477} },
      { :name => "name", :values => %w{ubuntu/images/*/ubuntu-*-*} },
    ],
    "ubuntu-14" => [
      { :name => "owner-id", :values => %w{099720109477} },
      { :name => "name", :values => %w{ubuntu/images/*/ubuntu-*-14*} },
    ],
    "ubuntu-12.04" => [
      { :name => "owner-id", :values => %w{099720109477} },
      { :name => "name", :values => %w{ubuntu/images/*/ubuntu-*-12.04*} },
    ],
    "ubuntu-x86_64" => [
      { :name => "owner-id", :values => %w{099720109477} },
      { :name => "name", :values => %w{ubuntu/images/*/ubuntu-*-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "ubuntu-14-x86_64" => [
      { :name => "owner-id", :values => %w{099720109477} },
      { :name => "name", :values => %w{ubuntu/images/*/ubuntu-*-14*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],

    "windows" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
    ],
    "windows-2008" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2008-RTM-English-*-Base-*
        Windows_Server-2008-SP*-English-*-Base-*} },
    ],
    "windows-2012" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-RTM-English-*-Base-*
        Windows_Server-2012-SP*-English-*-Base-*} },
    ],
    "windows-2012r2" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
    ],
    "windows-2012sp1" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-SP1-English-*-Base-*} },
    ],
    "windows-2012rtm" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-RTM-English-*-Base-*} },
    ],
    "windows-2012r2sp1" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-R2_SP1-English-*-Base-*} },
    ],
    "windows-2012r2rtm" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*} },
    ],
    "windows-x86_64" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "windows-2012r2-x86_64" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "windows-server" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-*-RTM-English-*-Base-*
        Windows_Server-*-SP*-English-*-Base-*
        Windows_Server-*-R*_RTM-English-*-Base-*
        Windows_Server-*-R*_SP*-English-*-Base-*
        Windows_Server-*-English-Full-Base-*} },
    ],
    "windows-server-2012r2-x86_64" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2012-R2_RTM-English-*-Base-*
        Windows_Server-2012-R2_SP*-English-*-Base-*} },
      { :name => "architecture", :values => %w{x86_64} },
    ],
    "windows-2016" => [
      { :name => "owner-alias", :values => %w{amazon} },
      { :name => "name", :values => %w{
        Windows_Server-2016-English-Full-Base-*} },
    ],
  }

  describe "Platform defaults" do
    PLATFORM_SEARCHES.each do |platform_name, filters|
      context "when platform is #{platform_name}" do
        let(:image) { FakeImage.new(:name => platform_name.split("-", 2)[0]) }

        it "searches for #{filters} and uses the resulting image" do
          expect(driver.ec2.resource).
            to receive(:images).with(:filters => filters).and_return([image])
          expect(driver.ec2.resource).
            to receive(:image).with(image.id).and_return(image)

          instance = new_instance(:platform_name => platform_name)
          expect(instance.driver.instance_generator.ec2_instance_data[:image_id]).
            to eq image.id
        end
      end
    end
  end

  context "when image_search is provided" do
    let(:image) { FakeImage.new(:name => "ubuntu") }
    let(:config) { { :image_search => { :name => "SuperImage" } } }

    context "and platform.name is a well known platform name" do
      it "searches for an image id without using the standard filters" do
        expect(driver.ec2.resource).
          to receive(:images).
          with(:filters => [{ :name => "name", :values => %w{SuperImage} }]).
          and_return([image])
        expect(driver.ec2.resource).
          to receive(:image).with(image.id).and_return(image)

        instance = new_instance(:platform_name => "ubuntu")
        expect(instance.driver.instance_generator.ec2_instance_data[:image_id]).
          to eq image.id
      end
    end

    context "and platform.name is not a well known platform name" do
      let(:image) { FakeImage.new(:name => "ubuntu") }
      it "does not search for (or find) an image, and informs the user they need to set image_id" do
        expect(driver.ec2.resource).
          to receive(:images).
          with(:filters => [{ :name => "name", :values => %w{SuperImage} }]).
          and_return([image])
        expect(driver.ec2.resource).
          to receive(:image).with(image.id).and_return(image)

        instance = new_instance(:platform_name => "blarghle")
        expect(instance.driver.instance_generator.ec2_instance_data[:image_id]).to eq image.id
      end
    end
  end
end
