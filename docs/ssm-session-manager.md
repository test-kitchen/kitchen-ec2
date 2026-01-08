# AWS SSM Session Manager Support

kitchen-ec2 now supports AWS Systems Manager (SSM) Session Manager as an alternative transport method to SSH/WinRM. This feature enables Test Kitchen to connect to EC2 instances without requiring direct network connectivity or SSH key management.

## Benefits

- **No SSH/WinRM network access required**: Connect to instances in private subnets without VPN or bastion hosts
- **Enhanced security**: No need to open SSH/RDP ports in security groups
- **Centralized audit logging**: All session activity is logged to CloudTrail
- **No SSH key management**: Eliminate the complexity of managing SSH key pairs for testing
- **Zero-trust compliance**: Access instances through AWS IAM authentication instead of network-based access

## Requirements

### Client Requirements

1. **AWS CLI**: Install the AWS CLI version 2.x or later
2. **Session Manager Plugin**: Install the Session Manager plugin for AWS CLI

### Instance Requirements

1. **SSM Agent**: Must be installed and running on the EC2 instance
2. **IAM Instance Profile**: Instance must have the `AmazonSSMManagedInstanceCore` managed policy or equivalent
3. **Network Access**: Outbound HTTPS (port 443) access to AWS SSM endpoints

## Configuration

### Basic Configuration

```yaml
driver:
  name: ec2
  use_ssm_session_manager: true
  iam_profile_name: my-ssm-enabled-profile
```

### Complete Example

```yaml
driver:
  name: ec2
  use_ssm_session_manager: true
  instance_type: t3.micro
  subnet_id: subnet-12345678
  iam_profile_name: kitchen-ec2-ssm-profile
  security_group_ids:
    - sg-87654321

platforms:
  - name: amazon2
  - name: ubuntu-20.04

suites:
  - name: default
    run_list:
      - recipe[my_cookbook::default]
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `use_ssm_session_manager` | `false` | Enable SSM Session Manager transport |
| `ssm_session_manager_document_name` | `nil` | Optional custom SSM document name |
| `iam_profile_name` | `nil` | IAM instance profile (required for SSM) |

## Additional Resources

- [AWS Systems Manager Session Manager Documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Session Manager Plugin Installation](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
