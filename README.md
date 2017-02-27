# <a name="title"></a> Kitchen::Ec2: A Test Kitchen Driver for Amazon EC2

[![Gem Version](https://badge.fury.io/rb/kitchen-ec2.svg)](https://badge.fury.io/rb/kitchen-ec2)
[![Build Status](https://travis-ci.org/test-kitchen/kitchen-ec2.svg?branch=master)](https://travis-ci.org/test-kitchen/kitchen-ec2)
[![Code Climate](https://codeclimate.com/github/test-kitchen/kitchen-ec2/badges/gpa.svg)](https://codeclimate.com/github/test-kitchen/kitchen-ec2)

A [Test Kitchen][kitchenci] Driver for Amazon EC2.

This driver uses the [aws sdk gem][aws_sdk_gem] to provision and destroy EC2
instances. Use Amazon's cloud for your infrastructure testing!

## Initial Setup

To get started, you need to install the software and set up your credentials and SSH key. Some of these steps you have probably already done, but we include them here for completeness.

1. Install the latest test-kitchen or ChefDK and put it in your path.
2. From this repository, type `bundle install; bundle exec rake install` to install the latest version of the driver.
3. Install the [AWS command line tools](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html).
4. Run `aws configure` to place your AWS credentials on the drive at ~/.aws/credentials.
5. Create your AWS SSH key. We recommend naming it with your username, but you can use any name:

     ```
     aws ec2 create-key-pair --key-name $USER | ruby -e "require 'json'; puts JSON.parse(STDIN.read)['KeyMaterial']" > ~/.ssh/$USER
     ```
6. `export AWS_SSH_KEY_ID=<your key name>`

## Quick Start

Once
that is done, create your kitchen file in your cookbook directory (or an empty
directory if you just want to get a feel for it):

1. `kitchen init -D kitchen-ec2`
2. Edit `.kitchen.yml` and add the aws_ssh_key_id to driver and a transport with
   an ssh_key:

   ```yaml
   transport:
     ssh_key: ~/.ssh/your_private_key_file
   ```
3. While you are in there, modify `centos-7.1` to `centos-7`.
3. `kitchen test`

It's that easy! This will set up and run centos and ubuntu flavored instances.

## Requirements

There are **no** external system requirements for this driver. However you
will need access to an [AWS][aws_site] account.  [IAM][iam_site] users should have, at a minimum, permission to manage the lifecycle of an EC2 instance along with modifying components specified in kitchen driver configs.  Consider using a permissive managed IAM policy like ``arn:aws:iam::aws:policy/AmazonEC2FullAccess`` or tailor one specific to your security requirements.

## Configuration

By automatically applying reasonable defaults wherever possible, kitchen-ec2 does a lot of work to make your life easier. Here is a description of some of the configuration parameters and what we do to default them.

### Specifying the Image

There are three ways to specify the image you use for the instance: `image_id`,
`image_search` and `platform.name`

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

#### `platform.name`

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

### AWS Authentication

In order to connect to AWS, you must specify the AWS access key id and secret key
for your account. There are 3 ways you do this, and we will try them in the
following order:

1. You can specify the access key and access secret (and optionally the session
   token) through config.  See the `aws_access_key_id` and `aws_secret_access_key`
   config sections below to see how to specify these in your .kitchen.yml or
   through environment variables.  If you would like to specify your session token
   use the environment variable `AWS_SESSION_TOKEN`.
2. The shared credentials ini file at `~/.aws/credentials`. This is the file
   populated by `aws configure` command line and used by AWS tools in general, so if
   you are set up for any other AWS tools, you probably already have this. You can
   specify multiple profiles in this file and select one with the `AWS_PROFILE`
   environment variable or the `shared_credentials_profile` driver config.  Read
   [this][credentials_docs] for more information.
3. From an instance profile when running on EC2.  This accesses the local
   metadata service to discover the local instance's IAM instance profile.

This precedence order is taken from http://docs.aws.amazon.com/sdkforruby/api/index.html#Configuration

The first method attempted that works will be used.  IE, if you want to auth
using the instance profile, you must not set any of the access key configs
or environment variables, and you must not specify a `~/.aws/credentials`
file.

Because the Test Kitchen test should be checked into source control and ran
through CI we no longer recommend storing the AWS credentials in the
`.kitchen.yml` file.  Instead, specify them as environment variables or in the
`~/.aws/credentials` file.

### Instance Login Configuration

The instances you create use credentials you specify which are *separate* from
the AWS credentials. Generally, SSH and WinRM use an AWS key pair which you
specify. You probably set this up in the Initial Setup.

#### `aws_ssh_key_id`

The ID of the AWS key pair you want to use.

The default will be read from the `AWS_SSH_KEY_ID` environment variable if set,
or `nil` otherwise.

If `aws_ssh_key_id` is specified, it must be one of the KeyName values shown by the AWS CLI: `aws ec2 describe-key-pairs`.
Otherwise, if not specified, you must either have a user pre-provisioned on the AMI, or provision the user using `user_data`.

#### `transport.ssh_key`

The private key file for the AWS key pair you want to use.

#### `transport.username`

This is not strictly a `driver` thing, but the username is a crucial component
of logging in to an instance. Different AMIs tend to provide different usernames.

If you use an official AMI (or create an image with the platform name in the
image name), we will use the default username for official AMIs for that platform.

#### `ebs_optimized`

Option to launch EC2 instance with optimized EBS volume. See
[Amazon EC2 Instance Types](http://aws.amazon.com/ec2/instance-types/) to find
out more about instance types that can be launched as EBS-optimized instances.

The default is `false`.

#### Password

For Windows instances the generated Administrator password is fetched
automatically from Amazon EC2 with the same private key as we use for
SSH logins to Linux.

### Windows Configuration

If you specify a platform name starting with `windows`, Test Kitchen will pull a
default AMI out of `amis.json` if one is not specified.

The default user_data will add any `username` with its associated `password`
from the transport options to the Aministrator group.  If no `username` is
specified then the default `administrator` is available.

AWS automatically generates an `administrator` password in the default
Windows AMIs.  Test Kitchen fetches this and stores it in the
`.kitchen/#{platform}.json` file.  If you need to `kitchen login` to the instance
and you have not specified your own `username` and `password` you can use
the `administrator` user and the password from this file.  Unfortunately
we cannot auto-fill the RDP password at this point.

### Other Configuration

#### `availability_zone`

The AWS [availability zone][region_docs] to use.  Only request
the letter designation - will attach this to the region used.

If not specified, your instances will be placed in an AZ of AWS's choice in your
region.

### <a name="config-instance_type"></a> `instance_type`

The EC2 [instance type][instance_docs] (also known as size) to use.

The default is `t2.micro` or `t1.micro`, depending on whether the image is `hvm`
or `paravirtual`. (`paravirtual` images are incompatible with `t2.micro`.)

### `security_group_ids`

An Array of EC2 [security groups][group_docs] which will be applied to the
instance.

The default is `["default"]`.

### `security_group_filter`

The EC2 [security group][group_docs] which will be applied to the instance,
specified by tag. Only one group can be specified this way.

The default is unset, or `nil`.

An example of usage:
```yaml
security_group_filter:
  tag:   'Name'
  value: 'example-group-name'
```

### `region`

**Required** The AWS [region][region_docs] to use.

If the environment variable `AWS_REGION` is populated that will be used.
Otherwise the default is `"us-east-1"`.

### `subnet_id`

The EC2 [subnet][subnet_docs] to use.

The default is unset, or `nil`.

### `subnet_filter`

The EC2 [subnet][subnet_docs] to use, specified by tag.

The default is unset, or `nil`.

An example of usage:
```yaml
subnet_filter:
  tag:   'Name'
  value: 'example-subnet-name'
```

### `tags`

The Hash of EC tag name/value pairs which will be applied to the instance.

The default is `{ "created-by" => "test-kitchen" }`.

### `user_data`

The user_data script or the path to a script to feed the instance.
Use bash to install dependencies or download artifacts before chef runs.
This is just for some cases. If you can do the stuff with chef, then do it with
chef!

On linux instances the default is unset, or `nil`.

On Windows instances we specify a default that enables winrm and
adds a non-administrator user specified in the `username` transport
options to the Administrator's User Group.

### `iam_profile_name`

The EC2 IAM profile name to use.

The default is `nil`.

### `spot_price`

The price you bid in order to submit a spot request. An additional step will be required during the spot request process submission. If no price is set, it will use an on-demand instance.

The default is `nil`.

### `instance_initiated_shutdown_behavior`

Control whether an instance should `stop` or `terminate` when shutdown is initiated from the instance using an operating system command for system shutdown.

The default is `nil`.

### block_duration_minutes

The [specified duration](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#fixed-duration-spot-instances) for a spot instance, in minutes. This value must be a multiple of 60 (60, 120, 180, 240, 300, or 360).
If no duration is set, the spot instance will remain active until it is terminated.

The default is `nil`.

### `http_proxy`

Specify a proxy to send AWS requests through.  Should be of the format `http://<host>:<port>`.

The default is `ENV["HTTPS_PROXY"] || ENV["HTTP_PROXY"]`.  If you have these environment variables set and do not want to use a proxy when contacting aws set `http_proxy: nil`.

**Note** - The AWS command line utility allow you to specify [two proxies](http://docs.aws.amazon.com/cli/latest/userguide/cli-http-proxy.html), one for HTTP and one for HTTPS.  The AWS Ruby SDK only allows you to specify 1 proxy and because all requests are `https://` this proxy needs to support HTTPS.

### `ssl_verify_peer`

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
  - name: ubuntu-12.04
  - name: centos-6.4
  - name: ubuntu-15.04
    driver:
      image_id: ami-83211eb3
      block_device_mappings:
        - device_name: /dev/sda1
          ebs:
            volume_type: standard
            virtual_name: test
            volume_size: 15
            delete_on_termination: true
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
  - name: windows-2008r2

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

## <a name="authors"></a> Authors

Created and maintained by [Fletcher Nichol][author] (<fnichol@nichol.ca>)

## <a name="license"></a> License

Apache 2.0 (see [LICENSE][license])


[author]:           https://github.com/fnichol
[issues]:           https://github.com/test-kitchen/kitchen-ec2/issues
[license]:          https://github.com/test-kitchen/kitchen-ec2/blob/master/LICENSE
[repo]:             https://github.com/test-kitchen/kitchen-ec2
[driver_usage]:     https://github.com/test-kitchen/kitchen-ec2
[chef_omnibus_dl]:  https://downloads.chef.io/chef-client/
[amis_json]:        https://github.com/test-kitchen/kitchen-ec2/blob/master/data/amis.json
[ami_docs]:         http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html
[aws_site]:         http://aws.amazon.com/
[iam_site]:         http://aws.amazon.com/iam
[credentials_docs]: http://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs
[aws_sdk_gem]:      http://docs.aws.amazon.com/sdkforruby/api/index.html
[group_docs]:       http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html
[instance_docs]:    http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html
[key_id_docs]:      http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/verifying-your-key-pair.html
[kitchenci]:        http://kitchen.ci/
[region_docs]:      http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
[subnet_docs]:      http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-subnet.html
[vpc_docs]:         http://docs.aws.amazon.com/AmazonVPC/latest/GettingStartedGuide/ExerciseOverview.html
