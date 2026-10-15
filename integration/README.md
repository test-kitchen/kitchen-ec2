# Integration suites

The unit suite stubs the AWS SDK, so it proves the driver *builds* the right
`RunInstances` call — never that EC2 accepts it, nor that the instance comes up
configured the way the call asked for. That gap is where the interesting bugs
live: a `licenses` key no EC2 API has ever had, a default instance type paired
with an image of the wrong architecture, an extra volume initialized as MBR and
silently capped at 2 TiB. Every one of those passed the unit suite, because a
stub encodes the same assumption the code does.

These suites close that gap. Each one launches a real EC2 instance and asserts,
**on the instance**, that the driver configured it as asked.

| Suite | What it proves |
| --- | --- |
| `default` | Per-platform AMI search, the free-tier instance type default, the auto-created security group and key pair, and login as the platform's own user. Runs on Ubuntu, Amazon Linux 2023, RHEL 9 and Debian 13. |
| `arm64` | The default instance type follows the image's architecture. An arm64 image paired with a t3 type does not launch at all. |
| `block-devices` | A resized root volume and an extra volume arrive attached at the requested sizes. |
| `user-data` | `user_data` naming a file is read, encoded, and run by cloud-init. |
| `metadata-options` | `http_tokens: required` really refuses IMDSv1, and the driver's tags reach the instance. |
| `spot` | The instance reports its own lifecycle as `spot`, rather than a market request that was quietly dropped. |
| `windows` | The generated PowerShell user data enables WinRM, the Administrator password is fetched and decrypted, and an extra volume comes up GPT-partitioned and formatted. |

## Running them

**These launch real, billable instances.** Everything is `t3.micro` except
Windows, which is `t3.medium`, and each suite lives for a few minutes.

```sh
export AWS_REGION=us-east-1     # defaults to us-east-1
bundle exec rake integration:list
bundle exec rake integration:test
```

One suite at a time:

```sh
bundle exec rake "integration:test[default-ubuntu-2404]"
```

`kitchen test` destroys each instance on success. A suite that fails leaves its
instance running, so **always** finish with:

```sh
bundle exec rake integration:destroy
```

Then check the EC2 console. A run killed part-way through can leave an
instance, a security group, a key pair or a dedicated host behind. Everything
this driver creates is tagged `created-by: test-kitchen`, and everything these
suites create is additionally tagged `kitchen-ec2-integration: true`, so a
console filter on that tag shows the lot.

Prefer a scratch account and a region you do not use for anything else.

## Credentials

The driver resolves credentials through the AWS SDK's standard chain, so
anything the AWS CLI can authenticate with works — `aws configure`, a profile
in `AWS_PROFILE`, or the environment variables.

The IAM principal needs to manage the full lifecycle of an instance plus the
security groups and key pairs the driver creates:

```text
ec2:RunInstances            ec2:TerminateInstances       ec2:DescribeInstances
ec2:CreateTags              ec2:DescribeImages           ec2:DescribeVpcs
ec2:DescribeSubnets         ec2:DescribeSecurityGroups   ec2:DescribeVolumes
ec2:CreateSecurityGroup     ec2:DeleteSecurityGroup      ec2:AuthorizeSecurityGroupIngress
ec2:CreateKeyPair           ec2:DeleteKeyPair            ec2:GetPasswordData
ec2:DescribeInstanceStatus  ec2:DescribeInstanceTypes
```

`AmazonEC2FullAccess` covers all of it and is a reasonable starting point for a
scratch account.

## CI

`.github/workflows/integration.yml` runs these weekly against `main`, and on
demand — **never on a pull request**. Secrets are unavailable to forks and
every run costs money, so a pull request trigger would fail for outside
contributors and hand anyone else a bill.

The job is skipped entirely unless the `AWS_ROLE_ARN` repository variable is
set, so a fork's scheduled build does not go red for credentials it will never
have.

Authentication is by **workload identity federation**: GitHub's OIDC token is
exchanged for short-lived AWS credentials, so no long-lived access key is
stored in the repository.

Two details that matter more than they look:

- **`Destroy everything` runs with `if: always()`.** A suite that leaks an
  instance turns a red build into a recurring bill.
- **`concurrency: ec2-integration` with `cancel-in-progress: false`.** Two
  overlapping runs share the account's instance limits and both fail — and
  cancelling a run mid-create is exactly how instances get orphaned.

### Setting it up

Two repository variables and one IAM role:

| Variable | Value |
| --- | --- |
| `AWS_ROLE_ARN` | The role CI assumes, e.g. `arn:aws:iam::123456789012:role/kitchen-ec2-integration` |
| `AWS_REGION` | Optional; defaults to `us-east-1` |

The role needs a trust policy accepting GitHub's OIDC provider, scoped to this
repository:

```json
{
  "Effect": "Allow",
  "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
    "StringLike": { "token.actions.githubusercontent.com:sub": "repo:test-kitchen/kitchen-ec2:*" }
  }
}
```

## Adding a suite

Add it to `kitchen.yml`, add its assertion script under `scripts/`, and add the
instance name to the matrix in `.github/workflows/integration.yml`.

Assertions live in the **shell provisioner**, not a verifier. The script is
transferred over the driver's own transport and executed on the instance, so
reaching the machine is part of every assertion, a non-zero exit fails the
suite, and there is no verifier licence to satisfy.

Write assertions against what the *instance* can see — the metadata service,
the block devices, the filesystem — not against what the driver was configured
with. A suite that only reads back its own configuration proves nothing the
unit tests do not already cover.
