# -*- encoding: utf-8 -*-
#
# Author:: Tyler Ball (<tball@chef.io>)
#
# Copyright (C) 2015, Fletcher Nichol
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

require "kitchen/driver/aws/instance_generator"
require "kitchen/driver/aws/client"
require "tempfile"
require "base64"
require "aws-sdk"

describe Kitchen::Driver::Aws::InstanceGenerator do

  let(:config) { Hash.new }
  let(:resource) { instance_double(Aws::EC2::Resource) }
  let(:ec2) { instance_double(Kitchen::Driver::Aws::Client, :resource => resource) }
  let(:logger) { instance_double(Logger) }
  let(:generator) { Kitchen::Driver::Aws::InstanceGenerator.new(config, ec2, logger) }

  describe "#prepared_user_data" do
    context "when config[:user_data] is a file" do
      let(:tmp_file) { Tempfile.new("prepared_user_data_test") }
      let(:config) { { :user_data => tmp_file.path } }

      before do
        tmp_file.write("foo\nbar")
        tmp_file.rewind
      end

      after do
        tmp_file.close
        tmp_file.unlink
      end

      it "reads the file contents" do
        expect(Base64.decode64(generator.prepared_user_data)).to eq("foo\nbar")
      end

      it "memoizes the file contents" do
        decoded = Base64.decode64(generator.prepared_user_data)
        expect(decoded).to eq("foo\nbar")
        tmp_file.write("other\nvalue")
        tmp_file.rewind
        expect(decoded).to eq("foo\nbar")
      end
    end
  end

  describe "#ec2_instance_data" do
    ec2_stub = Aws::EC2::Client.new(:stub_responses => true)

    ec2_stub.stub_responses(
      :describe_subnets,
      :subnets => [
        {
          :subnet_id  => "s-123",
          :tags       => [{ :key => "foo", :value => "bar" }],
        },
      ]
    )

    ec2_stub.stub_responses(
      :describe_security_groups,
      :security_groups => [
        {
          :group_id => "sg-123",
          :tags => [{ :key => "foo", :value => "bar" }],
        },
      ]
    )

    it "returns empty on nil" do
      expect(generator.ec2_instance_data).to eq(
        :instance_type => nil,
        :ebs_optimized => nil,
        :image_id => nil,
        :key_name => nil,
        :subnet_id => nil,
        :private_ip_address => nil
      )
    end

    context "when populated with minimum requirements" do
      let(:config) do
        {
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :subnet_id                    => "s-456",
          :private_ip_address           => "0.0.0.0",
        }
      end

      it "returns the minimum data" do
        expect(generator.ec2_instance_data).to eq(
           :instance_type => "micro",
           :ebs_optimized => true,
           :image_id => "ami-123",
           :key_name => nil,
           :subnet_id => "s-456",
           :private_ip_address => "0.0.0.0"
        )
      end
    end

    context "when populated with ssh key" do
      let(:config) do
        {
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :aws_ssh_key_id               => "key",
          :subnet_id                    => "s-456",
          :private_ip_address           => "0.0.0.0",
        }
      end

      it "returns the minimum data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => "micro",
          :ebs_optimized => true,
          :image_id => "ami-123",
          :key_name => "key",
          :subnet_id => "s-456",
          :private_ip_address => "0.0.0.0"
        )
      end
    end

    context "when provided subnet tag instead of id" do
      let(:config) do
        {
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :aws_ssh_key_id               => "key",
          :subnet_id                    => nil,
          :region                       => "us-west-2",
          :subnet_filter =>
            {
              :tag   => "foo",
              :value => "bar",
            },
        }
      end

      it "generates id from the provided tag" do
        allow(::Aws::EC2::Client).to receive(:new).and_return(ec2_stub)
        expect(ec2_stub).to receive(:describe_subnets).with(
          :filters => [
            {
              :name => "tag:foo",
              :values => ["bar"],
            },
          ]
        ).and_return(ec2_stub.describe_subnets)
        expect(generator.ec2_instance_data[:subnet_id]).to eq("s-123")
      end
    end

    context "when provided security_group tag instead of id" do
      let(:config) do
        {
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :aws_ssh_key_id               => "key",
          :subnet_id                    => "s-123",
          :security_group_ids           => nil,
          :region                       => "us-west-2",
          :security_group_filter =>
            {
              :tag   => "foo",
              :value => "bar",
            },
        }
      end

      it "generates id from the provided tag" do
        allow(::Aws::EC2::Client).to receive(:new).and_return(ec2_stub)
        expect(ec2_stub).to receive(:describe_security_groups).with(
          :filters => [
            {
              :name => "tag:foo",
              :values => ["bar"],
            },
          ]
        ).and_return(ec2_stub.describe_security_groups)
        expect(generator.ec2_instance_data[:security_group_ids]).to eq(["sg-123"])
      end
    end

    context "when passed an empty block_device_mappings" do
      let(:config) do
        {
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :aws_ssh_key_id               => "key",
          :subnet_id                    => "s-456",
          :private_ip_address           => "0.0.0.0",
          :block_device_mappings        => [],
        }
      end

      it "does not return block_device_mappings" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => "micro",
          :ebs_optimized => true,
          :image_id => "ami-123",
          :key_name => "key",
          :subnet_id => "s-456",
          :private_ip_address => "0.0.0.0"
        )
      end
    end

    context "when availability_zone is provided as 'eu-west-1c'" do
      let(:config) do
        {
          :region => "eu-east-1",
          :availability_zone => "eu-west-1c",
        }
      end
      it "returns that in the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :availability_zone => "eu-west-1c" }
        )
      end
    end

    context "when availability_zone is provided as 'c'" do
      let(:config) do
        {
          :region => "eu-east-1",
          :availability_zone => "c",
        }
      end
      it "adds the region to it in the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :availability_zone => "eu-east-1c" }
        )
      end
    end

    context "when availability_zone is not provided" do
      let(:config) do
        {
          :region => "eu-east-1",
        }
      end
      it "is not added to the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil
        )
      end
    end

    context "when availability_zone and tenancy are provided" do
      let(:config) do
        {
          :region => "eu-east-1",
          :availability_zone => "c",
          :tenancy => "dedicated",
        }
      end
      it "adds the region to it in the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :availability_zone => "eu-east-1c",
                          :tenancy => "dedicated" }
        )
      end
    end

    context "when tenancy is provided but availability_zone isn't" do
      let(:config) do
        {
          :region => "eu-east-1",
          :tenancy => "default",
        }
      end
      it "is not added to the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :tenancy => "default" }
        )
      end
    end

    context "when tenancy is not supported" do
      let(:config) do
        {
          :region => "eu-east-1",
          :tenancy => "ephemeral",
        }
      end
      it "is not added to the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil
        )
      end
    end

    context "when availability_zone and tenancy are provided" do
      let(:config) do
        {
          :region => "eu-east-1",
          :availability_zone => "c",
          :tenancy => "dedicated",
        }
      end
      it "adds the region to it in the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :availability_zone => "eu-east-1c",
                          :tenancy => "dedicated" }
        )
      end
    end

    context "when tenancy is provided but availability_zone isn't" do
      let(:config) do
        {
          :region => "eu-east-1",
          :tenancy => "default",
        }
      end
      it "is not added to the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :placement => { :tenancy => "default" }
        )
      end
    end

    context "when tenancy is not supported" do
      let(:config) do
        {
          :region => "eu-east-1",
          :tenancy => "ephemeral",
        }
      end
      it "is not added to the instance data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil
        )
      end
    end

    context "when subnet_id is provided" do
      let(:config) do
        {
          :subnet_id => "s-456",
        }
      end

      it "adds a network_interfaces block" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => "s-456",
          :private_ip_address => nil
        )
      end
    end

    context "when associate_public_ip is provided" do
      let(:config) do
        {
          :associate_public_ip => true,
        }
      end

      it "adds a network_interfaces block" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => nil,
          :ebs_optimized => nil,
          :image_id => nil,
          :key_name => nil,
          :subnet_id => nil,
          :private_ip_address => nil,
          :network_interfaces => [{
            :device_index => 0,
            :associate_public_ip_address => true,
            :delete_on_termination => true,
          }]
        )
      end

      context "and subnet is provided" do
        let(:config) do
          {
            :associate_public_ip => true,
            :subnet_id => "s-456",
          }
        end

        it "adds a network_interfaces block" do
          expect(generator.ec2_instance_data).to eq(
            :instance_type => nil,
            :ebs_optimized => nil,
            :image_id => nil,
            :key_name => nil,
            :private_ip_address => nil,
            :network_interfaces => [{
              :device_index => 0,
              :associate_public_ip_address => true,
              :delete_on_termination => true,
              :subnet_id => "s-456",
            }]
          )
        end
      end

      context "and security_group_ids is provided" do
        let(:config) do
          {
            :associate_public_ip => true,
            :security_group_ids => ["sg-789"],
          }
        end

        it "adds a network_interfaces block" do
          expect(generator.ec2_instance_data).to eq(
            :instance_type => nil,
            :ebs_optimized => nil,
            :image_id => nil,
            :key_name => nil,
            :subnet_id => nil,
            :private_ip_address => nil,
            :network_interfaces => [{
              :device_index => 0,
              :associate_public_ip_address => true,
              :delete_on_termination => true,
              :groups => ["sg-789"],
            }]
          )
        end

        it "accepts a single string value" do
          config[:security_group_ids] = "only-one"

          expect(generator.ec2_instance_data).to include(
            :network_interfaces => [{
              :device_index => 0,
              :associate_public_ip_address => true,
              :delete_on_termination => true,
              :groups => ["only-one"],
            }]
          )
        end
      end

      context "and private_ip_address is provided" do
        let(:config) do
          {
            :associate_public_ip => true,
            :private_ip_address => "0.0.0.0",
          }
        end

        it "adds a network_interfaces block" do
          expect(generator.ec2_instance_data).to eq(
            :instance_type => nil,
            :ebs_optimized => nil,
            :image_id => nil,
            :key_name => nil,
            :subnet_id => nil,
            :network_interfaces => [{
              :device_index => 0,
              :associate_public_ip_address => true,
              :delete_on_termination => true,
              :private_ip_address => "0.0.0.0",
            }]
          )
        end
      end
    end

    context "when provided the maximum config" do
      let(:config) do
        {
          :availability_zone            => "eu-west-1a",
          :instance_type                => "micro",
          :ebs_optimized                => true,
          :image_id                     => "ami-123",
          :aws_ssh_key_id               => "key",
          :subnet_id                    => "s-456",
          :private_ip_address           => "0.0.0.0",
          :block_device_mappings => [
            {
              :device_name => "/dev/sda2",
              :virtual_name => "test",
              :ebs => {
                :volume_size => 15,
                :delete_on_termination => false,
                :volume_type => "gp2",
                :snapshot_id => "id",
              },
            },
          ],
          :security_group_ids => ["sg-789"],
          :user_data => "foo",
          :iam_profile_name => "iam-123",
          :associate_public_ip => true,
        }
      end

      it "returns the maximum data" do
        expect(generator.ec2_instance_data).to eq(
          :instance_type => "micro",
          :ebs_optimized => true,
          :image_id => "ami-123",
          :key_name => "key",
          :block_device_mappings => [
            {
              :device_name => "/dev/sda2",
              :virtual_name => "test",
              :ebs => {
                :volume_size => 15,
                :delete_on_termination => false,
                :volume_type => "gp2",
                :snapshot_id => "id",
              },
            },
          ],
          :iam_instance_profile => { :name => "iam-123" },
          :network_interfaces => [{
            :device_index => 0,
            :associate_public_ip_address => true,
            :subnet_id => "s-456",
            :delete_on_termination => true,
            :groups => ["sg-789"],
            :private_ip_address =>  "0.0.0.0",
          }],
          :placement => { :availability_zone => "eu-west-1a" },
          :user_data => Base64.encode64("foo")
        )
      end
    end
  end
end
