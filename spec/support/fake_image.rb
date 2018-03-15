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
