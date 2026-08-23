# kitchen-ec2

[![Gem Version](https://badge.fury.io/rb/kitchen-ec2.svg)](https://badge.fury.io/rb/kitchen-ec2)
[![Test](https://github.com/test-kitchen/kitchen-ec2/actions/workflows/lint.yml/badge.svg)](https://github.com/test-kitchen/kitchen-ec2/actions/workflows/lint.yml)

A [Test Kitchen](https://kitchen.ci/) driver that creates and destroys [Amazon EC2](https://aws.amazon.com/ec2/) instances, so you can test your cookbooks and infrastructure code on real AWS machines. It uses the [AWS SDK for Ruby](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/) to talk to EC2.

The driver applies sensible defaults wherever it can: if you only specify a platform, it will find a suitable AMI, pick a free-tier instance type, create a security group, and manage an SSH key for you.

> This documentation uses [Cinc Workstation](https://cinc.sh/) and the `cinc` commands throughout. Everything here works identically with Chef Workstation — see [Using with Chef](#using-with-chef).

## Requirements

- Ruby 3.1 or later (already satisfied if you use Cinc Workstation)
- An [AWS account](https://aws.amazon.com/) and credentials
- The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/installing.html), which is the easiest way to configure those credentials

There are no other system requirements. The IAM user or role you use needs, at
minimum, permission to manage the lifecycle of an EC2 instance, plus any other
components your `kitchen.yml` touches (security groups, key pairs, dedicated
hosts). The managed policy `arn:aws:iam::aws:policy/AmazonEC2FullAccess` is a
permissive starting point; tailor a tighter one to your own requirements.

> **Cost warning:** this driver launches real, billable EC2 instances. Always
> run `cinc kitchen destroy` when you are finished, and check the EC2 console if
> a run fails partway through.

## Installation

This driver ships as part of [Cinc Workstation](https://cinc.sh/start/workstation/). If you have Cinc Workstation installed, there is nothing else to install.

To install it into a standalone Ruby:

```sh
gem install kitchen-ec2
```

Or with Bundler, add it to your `Gemfile`:

```ruby
gem "kitchen-ec2"
```

...then run `bundle install`.

## Authentication

Credentials are never set in `kitchen.yml`. The driver hands resolution to the
AWS SDK's standard credential chain, so anything the AWS CLI can authenticate
with works here too:

- The standard `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and
  `AWS_SESSION_TOKEN` environment variables
- A profile in the shared credentials file, named with
  `shared_credentials_profile` or `AWS_PROFILE`
- An instance profile or container role, when running on AWS

Naming a profile explicitly takes precedence over the environment variables;
with no profile named, the environment variables win.

The simplest setup is to run the AWS CLI configuration wizard once:

```sh
aws configure
```

There are no `aws_access_key_id`, `aws_secret_access_key` or
`aws_session_token` driver options. They were removed, and setting one now
stops the run:

```text
aws_access_key_id is no longer a valid config option, please use
ENV['AWS_ACCESS_KEY_ID'] or ~/.aws/credentials.
```

Use the environment or a profile instead.

## Quick Start

Because the driver defaults so much, a working `kitchen.yml` can be very small:

```yaml
---
driver:
  name: ec2

provisioner:
  name: cinc_infra

verifier:
  name: cinc_auditor

platforms:
  - name: ubuntu-22.04
  - name: amazon-2023

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

Then run the full test cycle:

```sh
cinc kitchen test
```

Or step through it:

```sh
cinc kitchen create    # launch the EC2 instance
cinc kitchen converge  # apply your cookbook
cinc kitchen verify    # run your tests
cinc kitchen destroy   # terminate the instance
```

## What the driver does for you

If you do not specify them, the driver will:

- **Find an AMI** matching the platform name, searching the official owner for that distribution
- **Pick an instance type**, defaulting to the free-tier `t3.micro` for HVM images
- **Create a security group** in the target VPC allowing inbound access on the transport's port, deleted on `destroy`
- **Create an SSH key pair**, deleted on `destroy`
- **Tag the instance** with `created-by: test-kitchen`

Set the corresponding options below to take control of any of these.

## Configuration

All options below are set under the `driver:` key in `kitchen.yml`.

### Credentials and region

| Option | Default | Description |
| --- | --- | --- |
| `region` | `$AWS_REGION`, else `"us-east-1"` | AWS region to launch in. |
| `availability_zone` | *AWS chooses* | Availability zone. A bare letter such as `a` is expanded against `region`, so `a` becomes `us-east-1a`. |
| `shared_credentials_profile` | `$AWS_PROFILE` | Named profile in the shared AWS credentials file. |
| `http_proxy` | `$HTTPS_PROXY`, else `$HTTP_PROXY` | Proxy used for AWS API calls. |
| `ssl_verify_peer` | `true` | Verify TLS certificates on AWS API calls. |
| `retry_limit` | `3` | Number of times the AWS SDK retries a failed API call. |

### Image

| Option | Default | Description |
| --- | --- | --- |
| `image_id` | *searched from platform* | Exact AMI ID to launch. Skips image search entirely. |
| `image_search` | `nil` | Hash of EC2 image filters used to find an AMI, overriding the platform's built-in search. |

Either the platform name must be one the driver knows how to search for, or you
must set `image_id` or `image_search`.

The login user is detected from the platform, so it usually does not need
setting. To override it, set it on the **transport**, not the driver:

```yaml
transport:
  username: ec2-user
```

`driver.username` was removed; setting it stops the run with an error pointing
at `transport.username`.

### Instance

| Option | Default | Description |
| --- | --- | --- |
| `instance_type` | `"t3.micro"` (HVM) | EC2 instance type. |
| `ebs_optimized` | `false` | Launch as EBS-optimized. |
| `delete_on_termination` | `true` | Delete the root volume when the instance terminates. |
| `block_device_mappings` | *from AMI* | Array of block device mapping hashes, for sizing the root volume or attaching extra volumes. |
| `iam_profile_name` | `nil` | Name of an IAM instance profile to attach. |
| `user_data` | *unset* | User data for the instance, given as a string or a path to a file. |
| `tags` | `{"created-by" => "test-kitchen"}` | Tags applied to the instance. |
| `tenancy` | `"default"` | Instance tenancy: `default`, `dedicated`, or `host`. |
| `instance_initiated_shutdown_behavior` | `nil` | `stop` or `terminate`, when the guest itself shuts down. |
| `metadata_options` | *AWS default* | Hash configuring the instance metadata service, e.g. to require IMDSv2. |
| `licenses` | *unset* | Array of `{license_configuration_arn: ...}` hashes for License Manager. |
| `placement` | *unset* | Hash of placement options: `affinity`, `availability_zone`, `group_id`, `group_name`, `host_id`, `host_resource_group_arn`, `partition_number`, `tenancy`. |

### Networking

| Option | Default | Description |
| --- | --- | --- |
| `subnet_id` | *default VPC subnet* | Subnet to launch into. |
| `subnet_filter` | `nil` | Hash (or array of hashes) of filters used to find a subnet, instead of naming one. |
| `security_group_ids` | *created automatically* | Array of security group IDs to attach. |
| `security_group_filter` | `nil` | Hash (or array of hashes) of filters used to find security groups. |
| `security_group_cidr_ip` | `"0.0.0.0/0"` | CIDR allowed inbound on the auto-created security group. Narrow this on shared accounts. |
| `associate_public_ip` | *subnet default* | Assign a public IP address. |
| `associate_ipv6` | `nil` | Assign an IPv6 address. |
| `private_ip_address` | `nil` | Specific private IP to assign. |
| `interface` | *auto* | Which address to connect to: `dns`, `public`, `private`, or `private_dns`. |
| `elastic_network_interface_id` | `nil` | ID of an existing ENI to attach after creation. |

### SSH key

| Option | Default | Description |
| --- | --- | --- |
| `aws_ssh_key_id` | `$AWS_SSH_KEY_ID` | Name of an existing EC2 key pair. If unset, a temporary key pair is created and deleted on destroy. |
| `aws_ssh_key_type` | `"rsa"` | Key type used when creating a temporary key pair, `rsa` or `ed25519`. |

### Spot instances

| Option | Default | Description |
| --- | --- | --- |
| `spot_price` | `nil` | Maximum spot price. Set to `on-demand` to bid the on-demand price. Enables a spot request. |
| `spot_wait` | `60` | Seconds to wait for a spot request to be fulfilled. |
| `block_duration_minutes` | `nil` | Duration for a fixed-duration spot instance, in minutes. |

### Dedicated hosts

| Option | Default | Description |
| --- | --- | --- |
| `allocate_dedicated_host` | `false` | Allocate a dedicated host before launching. |
| `deallocate_dedicated_host` | `false` | Release the dedicated host on destroy. |

### Connectivity

For a full explanation of Session Manager, including its IAM requirements and why you might prefer it, see [docs/ssm-session-manager.md](docs/ssm-session-manager.md).

| Option | Default | Description |
| --- | --- | --- |
| `use_ssm_session_manager` | `false` | Connect through AWS Systems Manager Session Manager instead of opening SSH or RDP ports. |
| `ssm_session_manager_document_name` | `nil` | SSM document to use for the session. |
| `use_instance_connect` | `false` | Use EC2 Instance Connect to push a temporary SSH key. |
| `instance_connect_endpoint_id` | `nil` | EC2 Instance Connect Endpoint ID, for reaching instances with no public IP. |
| `instance_connect_max_tunnel_duration` | `3600` | Maximum tunnel duration in seconds for Instance Connect. |

### Waiting and retries

| Option | Default | Description |
| --- | --- | --- |
| `retryable_tries` | `60` | Number of times to poll for the instance to become ready. |
| `retryable_sleep` | `5` | Seconds between readiness polls. |
| `skip_cost_warning` | `false` | Suppress the warning printed about incurring AWS charges. |

## Transport options

The driver supports three ways of reaching an instance:

- **SSH / WinRM** (default) — traditional network access, requiring an open port
- **EC2 Instance Connect** — temporary SSH keys pushed through the AWS API, optionally via an endpoint so no public IP is needed
- **SSM Session Manager** — access through Systems Manager, with no inbound ports at all and full session auditing

Session Manager is documented in detail in [docs/ssm-session-manager.md](docs/ssm-session-manager.md).

## Examples

### Pinning the AMI and instance type

```yaml
driver:
  name: ec2
  region: us-west-2
  image_id: ami-0abcdef1234567890
  instance_type: m6i.large
```

### Searching for an AMI

```yaml
driver:
  name: ec2
  region: us-west-2
  image_search:
    owner-id: "099720109477"
    name: "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
```

### Launching into a specific VPC subnet

```yaml
driver:
  name: ec2
  region: us-west-2
  subnet_id: subnet-0abcdef1234567890
  security_group_ids:
    - sg-0abcdef1234567890
  associate_public_ip: true
```

### Finding the subnet by tag instead of naming it

```yaml
driver:
  name: ec2
  region: us-west-2
  subnet_filter:
    tag: Environment
    value: test
```

### Resizing the root volume

```yaml
driver:
  name: ec2
  block_device_mappings:
    - device_name: /dev/sda1
      ebs:
        volume_type: gp3
        volume_size: 50
        delete_on_termination: true
```

### Spot instances

```yaml
driver:
  name: ec2
  instance_type: m6i.large
  spot_price: on-demand
  spot_wait: 120
```

### No inbound ports, via Session Manager

```yaml
driver:
  name: ec2
  use_ssm_session_manager: true
  iam_profile_name: kitchen-ssm-instance-profile
  associate_public_ip: false
```

### Requiring IMDSv2

```yaml
driver:
  name: ec2
  metadata_options:
    http_tokens: required
    http_put_response_hop_limit: 1
    instance_metadata_tags: enabled
```

### Tagging for cost tracking

```yaml
driver:
  name: ec2
  tags:
    created-by: test-kitchen
    owner: platform-team
    cost-center: "1234"
```

## Using with Chef

This driver is not tied to Cinc. The examples above use Cinc Workstation and the `cinc_infra` provisioner, but the driver works exactly the same with [Chef Workstation](https://www.chef.io/downloads/tools/workstation) — run `kitchen` instead of `cinc kitchen`, and use `chef_infra` instead of `cinc_infra`:

```yaml
provisioner:
  name: chef_infra

verifier:
  name: inspec
```

No driver configuration changes are needed.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/test-kitchen/kitchen-ec2). See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, how to run the tests, and the release process.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](https://github.com/test-kitchen/kitchen-ec2/blob/main/LICENSE) for details.
