# kitchen-ec2

[![Gem Version](https://badge.fury.io/rb/kitchen-ec2.svg)](https://badge.fury.io/rb/kitchen-ec2)
![CI](https://github.com/test-kitchen/kitchen-ec2/workflows/CI/badge.svg?branch=master)

A [Test Kitchen][kitchenci] Driver for Amazon EC2.

This driver uses the [aws sdk gem][aws_sdk_gem] to provision and destroy EC2
instances. Use Amazon's cloud for your infrastructure testing!

## Quick Start

1. Install [Chef Workstation](https://downloads.chef.io/products/workstation). If testing things other than Chef Infra cookbooks, please consult your driver's documentation for information on what to install.
2. Install the [AWS command line tools](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
3. Run `aws configure`. This will set up your AWS credentials for both the AWS CLI tools and kitchen-ec2.
4. Add or edit the `driver` section of your `kitchen.yml`:

   ```yaml
   driver:
     name: ec2
   ```

5. Run `kitchen test`.

## Requirements

There are **no** external system requirements for this driver. However you
will need access to an [AWS][aws_site] account.  [IAM][iam_site] users should have, at a minimum, permission to manage the lifecycle of an EC2 instance along with modifying components specified in kitchen driver configs.  Consider using a permissive managed IAM policy like ``arn:aws:iam::aws:policy/AmazonEC2FullAccess`` or tailor one specific to your security requirements.

## Configuration

By automatically applying reasonable defaults wherever possible, kitchen-ec2 does a lot of work to make your life easier.
See the [kitchen.ci kitchen-ec2 docs](https://kitchen.ci/docs/drivers/aws/) for a complete list of configuration options.

## Development

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

## License

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
[ssh_over_ssm]:     https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-enable-ssh-connections.html
[vpc_docs]:         https://docs.aws.amazon.com/AmazonVPC/latest/GettingStartedGuide/ExerciseOverview.html
