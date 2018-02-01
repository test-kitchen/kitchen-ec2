# <a name="title"></a> Kitchen::Ec2: A Test Kitchen Driver for Amazon EC2

[![Gem Version](https://badge.fury.io/rb/kitchen-ec2.svg)](https://badge.fury.io/rb/kitchen-ec2)
[![Build Status](https://travis-ci.org/test-kitchen/kitchen-ec2.svg?branch=master)](https://travis-ci.org/test-kitchen/kitchen-ec2)
[![Code Climate](https://codeclimate.com/github/test-kitchen/kitchen-ec2/badges/gpa.svg)](https://codeclimate.com/github/test-kitchen/kitchen-ec2)

A [Test Kitchen][kitchenci] Driver for Amazon EC2.

This driver uses the [aws sdk gem][aws_sdk_gem] to provision and destroy EC2
instances. Use Amazon's cloud for your infrastructure testing!

## Quick Start

1. Install [ChefDK](https://downloads.chef.io/chefdk). If testing things other
   than Chef cookbooks, please consult your driver's documentation for information
   on what to install.
2. Install the [AWS command line tools](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
3. Run `aws configure`. This will set up your AWS credentials for both the AWS
   CLI tools and kitchen-ec2.
4. Add or exit the `driver` section of your `.kitchen.yml`:

   ```yaml
   driver:
     name: ec2
   ```
5. Run `kitchen test`.

## Requirements

There are **no** external system requirements for this driver. However you
will need access to an [AWS][aws_site] account.  [IAM][iam_site] users should have, at a minimum, permission to manage the lifecycle of an EC2 instance along with modifying components specified in kitchen driver configs.  Consider using a permissive managed IAM policy like ``arn:aws:iam::aws:policy/AmazonEC2FullAccess`` or tailor one specific to your security requirements.

## Configuration

By automatically applying reasonable defaults wherever possible, kitchen-ec2 does a lot of work to make your life easier. Here is a description of some of the configuration parameters and what we do to default them.

### Specifying the Image

There are three ways to specify the image you use for the instance: the `platform`
name, `image_id`, and `image_search`.

#### `platform` Name

The third way to specify the image is by leaving `image_id` and `image_search`
blank, and specifying a standard platform name.

```yaml
platforms:
  - name: ubuntu-14.04
```

If you use the platform name `ubuntu`, `windows`, `rhel`, `debian`, `centos`, `freebsd` or `fedora`, kitchen-ec2 will search for the latest matching official image of
the given OS in your region. You may leave versions off, specify partial versions,
and you may specify architecture to distinguish 32- and 64-bit. Some examples:

```yaml
platforms:
  # The latest stable minor+patch release of rhel 6
  - name: rhel-6
  # The latest patch release of CentOS 6.3
  - name: centos-6.3
  # The latest patch release of Amazon Linux 2017.03
  - name: amazon-2017.03
  # 32-bit version of latest major+minor+patch release of Ubuntu
  - name: ubuntu-i386
  # 32-bit version of Debian 6
  - name: debian-6-i386
  # Latest 32-bit stable minor release of freebsd 10
  - name: freebsd-10-i386
  # The latest stable major+minor+patch release of Fedora
  - name: fedora
  # The most recent service-pack for Windows 2012 (not R2)
  - name: windows-2012
  # The most recent service-pack for Windows 2012R2
  - name: windows-2012r2
  # Windows 2008 RTM (not R2, no service pack)
  - name: windows-2008rtm
  # Windows 2008R2 SP1
  - name: windows-2008r2sp1
```

We always pick the highest released stable version that matches your regex, and
follow the other `image_search` rules for preference.

#### `image_id`

`image_id` can be set explicitly. It must be an ami in the region you are
working with!

```yaml
platforms:
  - name: centos-7
    driver:
      image_id: ami-96a818fe
```

image_id's have a format like ami-748e2903. The image_id values appear next to the image names when you select 'Launch Instance' from the AWS EC2 console. You can also see the list from the AWS CLI ````aws ec2 describe-images````.

#### `image_search`

`image_search` lets you specify a series of key/value pairs to search for the
image. If a value is set to an array, then *any* of those values will match.
You can learn more about the available filters in the AWS CLI doc under `--filters` [here](http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html).

```yaml
platforms:
  - name: ubuntu-14.04
    driver:
      image_search:
        owner-id: "099720109477"
        name: ubuntu/images/*/ubuntu-*-14.04*
```

In the event that there are multiple matches (as sometimes happens), we sort to
get the best results. In order of priority from greatest to least, we prefer:

- HVM images over paravirtual
- SSD support over magnetic drives
- 64-bit over 32-bit
- The most recently created image (to pick up patch releases)

Note that the image_search method *requires* that the AMI image names be in a specific format.
Some examples are:

- Windows-2012
- Windows-2012r2
- Windows-2012r2sp1
- RHEL-7.2

It is safest to use the same naming convention as used by the public images published by the OS vendors on the AWS marketplace.

### AWS Authentication

In order to connect to AWS, you must specify AWS credentials. We rely on the SDK
to find credentials in the standard way, documented here:
https://github.com/aws/aws-sdk-ruby/#configuration

The SDK Chain will search environment variables, then config files, then IAM role
data from the instance profile, in that order. In the case config files being
present, the 'default' profile will be used unless `shared_credentials_profile`
is defined to point to another profile.

Because the Test Kitchen test should be checked into source control and ran
through CI we no longer support storing the AWS credentials in the
`.kitchen.yml` file.

### Instance Login Configuration

The instances you create use credentials you specify which are *separate* from
the AWS credentials. Generally, SSH and WinRM use an AWS key pair which you
specify.

#### SSH

The `aws_ssh_key_id` value is the name of the AWS key pair you want to use. The default will be read from the `AWS_SSH_KEY_ID` environment variable if set.  If a key ID is not specified, a temporary key will be created for you (**>= 2.1.0**).

To see a list of existing key pair IDs in a region, run `aws ec2 describe-key-pairs --region us-east-1`.

When using an existing key, ensure that the private key is configured in your
Test Kitchen `transport`, either directly or made available via `ssh-agent`:

```yaml
transport:
  ssh_key: ~/.ssh/mykey.pem
```

For standard platforms we automatically provide the SSH username, but when
specifying your own AMI you may need to configure that as well.

#### WinRM

For Windows instances the generated Administrator password is fetched automatically from Amazon EC2 with the same private key as we use for SSH.

Unfortunately the RDP file format does not allow including login credentials, so `kitchen login` with WinRM cannot automatically log in for you.

### Other Configuration

#### `availability_zone`

The AWS [availability zone][region_docs] to use.  Only request
the letter designation - will attach this to the region used.

If not specified, your instances will be placed in an AZ of AWS's choice in your
region.

#### `instance_type`

The EC2 [instance type][instance_docs] (also known as size) to use.

The default is `t2.micro` or `t1.micro`, depending on whether the image is `hvm`
or `paravirtual`. (`paravirtual` images are incompatible with `t2.micro`.)

#### `security_group_ids`

An Array of EC2 [security groups][group_docs] which will be applied to the
instance. If no security group is specified, a temporary group will be created
automatically which allows SSH and WinRM (**>= 2.1.0**).

#### `security_group_filter`

The EC2 [security group][group_docs] which will be applied to the instance,
specified by tag. Only one group can be specified this way.

The default is unset, or `nil`.

An example of usage:
```yaml
security_group_filter:
  tag:   'Name'
  value: 'example-group-name'
```

#### `region`

**Required** The AWS [region][region_docs] to use.

If the environment variable `AWS_REGION` is populated that will be used.
Otherwise the default is `"us-east-1"`.

#### `subnet_id`

The EC2 [subnet][subnet_docs] to use.

The default is unset, or `nil`.

#### `subnet_filter`

The EC2 [subnet][subnet_docs] to use, specified by tag.

The default is unset, or `nil`.

An example of usage:
```yaml
subnet_filter:
  tag:   'Name'
  value: 'example-subnet-name'
```

#### `tags`

The Hash of EC tag name/value pairs which will be applied to the instance.

The default is `{ "created-by" => "test-kitchen" }`.

#### `user_data`

The user_data script or the path to a script to feed the instance.
Use bash to install dependencies or download artifacts before chef runs.
This is just for some cases. If you can do the stuff with chef, then do it with
chef!

On linux instances the default is unset, or `nil`.

On Windows instances we specify a default that enables winrm and
adds a non-administrator user specified in the `username` transport
options to the Administrator's User Group.

#### `iam_profile_name`

The EC2 IAM profile name to use. The default is `nil`.

Note: The user, whose AWS credentials you have defined, not only needs `AmazonEC2FullAccess` permissions, but also the ability to execute `iam:PassRole`.
Hence, use a policy like below when using this option:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::123456789:role/RoleName"
        }
    ]
}
```

See [AWS documentation](https://aws.amazon.com/de/blogs/security/granting-permission-to-launch-ec2-instances-with-iam-roles-passrole-permission/) for more details.


#### `spot_price`

The price you bid in order to submit a spot request. An additional step will be required during the spot request process submission. If no price is set, it will use an on-demand instance.

The default is `nil`.

#### `instance_initiated_shutdown_behavior`

Control whether an instance should `stop` or `terminate` when shutdown is initiated from the instance using an operating system command for system shutdown.

The default is `nil`.

#### `block_duration_minutes`

The [specified duration](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#fixed-duration-spot-instances) for a spot instance, in minutes. This value must be a multiple of 60 (60, 120, 180, 240, 300, or 360).
If no duration is set, the spot instance will remain active until it is terminated.

The default is `nil`.

#### `http_proxy`

Specify a proxy to send AWS requests through.  Should be of the format `http://<host>:<port>`.

The default is `ENV["HTTPS_PROXY"] || ENV["HTTP_PROXY"]`.  If you have these environment variables set and do not want to use a proxy when contacting aws set `http_proxy: nil`.

**Note** - The AWS command line utility allow you to specify [two proxies](http://docs.aws.amazon.com/cli/latest/userguide/cli-http-proxy.html), one for HTTP and one for HTTPS.  The AWS Ruby SDK only allows you to specify 1 proxy and because all requests are `https://` this proxy needs to support HTTPS.

#### `ssl_verify_peer`

If you need to turn off ssl certificate verification for HTTP calls made to AWS, set `ssl_verify_peer: false`.

### Disk Configuration

#### <a name="config-block_device_mappings"></a> `block_device_mappings`

A list of block device mappings for the machine.  An example of all available keys looks like:
```yaml
block_device_mappings:
  - device_name: /dev/sda
    ebs:
      volume_size: 20
      delete_on_termination: true
  - device_name: /dev/sdb
    ebs:
      volume_type: gp2
      virtual_name: test
      volume_size: 15
      delete_on_termination: true
      snapshot_id: snap-0015d0bc
  - device_name: /dev/sdc
    ebs:
      volume_size: 100
      delete_on_termination: true
      volume_type: io1
      iops: 100
```

See
[Amazon EBS Volume Types](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html)
to find out more about volume types.

If you have a block device mapping with a `device_name` equal to the root storage device name on your
[image](#config-image-id) then the provided mapping will replace the settings in the image.

If this is not provided it will use the default block_device_mappings from the AMI.

#### `ebs_optimized`

Option to launch EC2 instance with optimized EBS volume. See
[Amazon EC2 Instance Types](http://aws.amazon.com/ec2/instance-types/) to find
out more about instance types that can be launched as EBS-optimized instances.

The default is `false`.

### Network and Communication Configuration

#### `associate_public_ip`

AWS does not automatically allocate public IP addresses for instances created
within non-default [subnets][subnet_docs]. Set this option to `true` to force
allocation of a public IP and associate it with the launched instance.

If you set this option to `false` when launching into a non-default
[subnet][subnet_docs], Test Kitchen will be unable to communicate with the
instance unless you have a VPN connection to your
[Virtual Private Cloud][vpc_docs].

The default is `true` if you have configured a [subnet_id](#config-subnet-id),
or `false` otherwise.

#### `private_ip_address`

The primary private IP address of your instance.

If you don't set this it will default to whatever DHCP address EC2 hands out.

#### `interface`

The place from which to derive the hostname for communicating with the instance.  May be `dns`, `public`, `private` or `private_dns`.  If this is unset, the driver will derive the hostname by failing back in the following order:

1. DNS Name
2. Public IP Address
3. Private IP Address
4. Private DNS Name

The default is unset. Under normal circumstances, the lookup will return the `Private IP Address`.

If the `Private DNS Name` is preferred over the private IP, it must be specified in the `.kitchen.yml` file

```ruby
driver:
  interface: private_dns
```

## Example

The following could be used in a `.kitchen.yml` or in a `.kitchen.local.yml`
to override default configuration.

```yaml
---
driver:
  name: ec2
  aws_ssh_key_id: id_rsa-aws
  security_group_ids: ["sg-1a2b3c4d"]
  region: us-west-2
  availability_zone: b
  require_chef_omnibus: true
  subnet_id: subnet-6e5d4c3b
  iam_profile_name: chef-client
  instance_type: m3.medium
  associate_public_ip: true
  interface: dns

transport:
  ssh_key: /path/to/id_rsa-aws
  connection_timeout: 10
  connection_retries: 5
  username: ubuntu

platforms:
  - name: ubuntu-16.04
  - name: centos-6.9
  - name: centos-7
    driver:
      image_id: ami-c7d092f7
      block_device_mappings:
        - device_name: /dev/sdb
          ebs:
            volume_type: gp2
            virtual_name: test
            volume_size: 8
            delete_on_termination: true
    transport:
      username: centos
  - name: windows-2012r2
  - name: windows-2016

suites:
# ...
```

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="license"></a> License

Apache 2.0 (see [LICENSE][license])


[author]:           https://github.com/fnichol
[issues]:           https://github.com/test-kitchen/kitchen-ec2/issues
[license]:          https://github.com/test-kitchen/kitchen-ec2/blob/master/LICENSE
[repo]:             https://github.com/test-kitchen/kitchen-ec2
[driver_usage]:     https://github.com/test-kitchen/kitchen-ec2
[chef_omnibus_dl]:  https://downloads.chef.io/chef
[amis_json]:        https://github.com/test-kitchen/kitchen-ec2/blob/master/data/amis.json
[ami_docs]:         http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html
[aws_site]:         http://aws.amazon.com/
[iam_site]:         http://aws.amazon.com/iam
[credentials_docs]: https://aws.amazon.com/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/
[aws_sdk_gem]:      https://docs.aws.amazon.com/sdkforruby/api/index.html
[group_docs]:       https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html
[instance_docs]:    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
[key_id_docs]:      https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
[kitchenci]:        https://kitchen.ci/
[region_docs]:      https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
[subnet_docs]:      https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
[vpc_docs]:         https://docs.aws.amazon.com/AmazonVPC/latest/GettingStartedGuide/ExerciseOverview.html
