class FakeImage
  def self.next_ami
    @n ||= 0
    @n += 1
    [format("ami-%08x", @n), Time.now + @n]
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
  attr_reader :id, :name, :creation_date, :architecture, :volume_type, :root_device_type, :virtualization_type, :root_device_name, :device_name

  def block_device_mappings
    [self]
  end

  def ebs
    self
  end
end
