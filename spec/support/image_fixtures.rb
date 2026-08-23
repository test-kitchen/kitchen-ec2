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

require "aws-sdk-ec2"

# Builders for the EC2 image objects the driver's platform detection and image
# selection code operates on.
#
# These return genuine `Aws::EC2::Image` resource objects rather than
# duck-typed stand-ins, so a change to the shape of the AWS SDK's image type
# fails these specs instead of silently passing against a fake.
module ImageFixtures
  # Attributes shared by every fixture image. Individual builders override what
  # the example under test actually cares about.
  DEFAULT_IMAGE_ATTRIBUTES = {
    architecture: "x86_64",
    root_device_type: "ebs",
    root_device_name: "/dev/sda1",
    virtualization_type: "hvm",
    volume_type: "gp3",
  }.freeze

  # Build a single EC2 image resource.
  #
  # `creation_date` and `image_id` are generated in increasing order when not
  # supplied, so images built later sort as newer.
  def build_image(name:, **overrides)
    attributes = DEFAULT_IMAGE_ATTRIBUTES.merge(overrides)
    volume_type = attributes.delete(:volume_type)
    sequence = next_image_sequence

    data = ::Aws::EC2::Types::Image.new(
      image_id: attributes.delete(:image_id) || format("ami-%08x", sequence),
      name: name,
      creation_date: attributes.delete(:creation_date) || image_creation_date(sequence),
      block_device_mappings: attributes.delete(:block_device_mappings) ||
        [block_device_mapping(attributes[:root_device_name], volume_type)],
      **attributes
    )

    ::Aws::EC2::Image.new(data.image_id, data: data, client: fixture_client)
  end

  # Build several images at once from a list of names.
  def build_images(*names)
    names.map { |name| build_image(name: name) }
  end

  # An `Aws::EC2::Resource` whose `#images` returns the supplied images.
  #
  # Image lookups go through `resource.images(filters:)`, so specs that exercise
  # selection need a resource rather than bare image objects. The stubbed client
  # records the request, letting a spec assert on the filters that were sent.
  def stub_image_resource(images)
    client = stub_ec2_client
    client.stub_responses(:describe_images, images: images.map { |image| image.data.to_h })
    ::Aws::EC2::Resource.new(client: client)
  end

  private

  # Fixture images never issue requests; they only need a client to satisfy the
  # resource constructor. Building one per image is pure waste, so share it.
  def fixture_client
    @fixture_client ||= stub_ec2_client
  end

  # A block device mapping for the image's root device, which is what
  # `sort_images` inspects when preferring SSD-backed images.
  def block_device_mapping(device_name, volume_type)
    ::Aws::EC2::Types::BlockDeviceMapping.new(
      device_name: device_name,
      ebs: ::Aws::EC2::Types::EbsBlockDevice.new(volume_type: volume_type)
    )
  end

  # Monotonically increasing counter, reset for each example so that image IDs
  # are stable and independent of the randomized example order.
  def next_image_sequence
    @image_sequence = (@image_sequence || 0) + 1
  end

  # A fixed base date plus the sequence number, so that fixture creation dates
  # are deterministic but still ordered.
  def image_creation_date(sequence)
    (Time.utc(2024, 1, 1) + (sequence * 86_400)).strftime("%Y-%m-%dT%H:%M:%S.000Z")
  end
end
