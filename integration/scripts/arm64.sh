#!/bin/sh
# An instance type runs one processor architecture, and EC2 rejects a launch
# pairing it with an image built for another. Defaulting to t3.micro for every
# hardware-virtualized image made every arm64 platform fail outright, so this
# suite asserts on the pairing rather than merely on reaching the machine.
set -eu

TOKEN=$(curl -sSf -X PUT http://169.254.169.254/latest/api/token \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 120')
instance_type=$(curl -sSf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)
arch=$(uname -m)

echo "instance-type: $instance_type"
echo "architecture:  $arch"

[ "$arch" = "aarch64" ] || {
  echo "FAIL: expected an arm64 image, got $arch" >&2
  exit 1
}

# t4g is the Graviton counterpart of t3. An x86_64 default here would not have
# launched at all, so reaching this line with the wrong type means the platform
# string was parsed as something other than arm64.
[ "$instance_type" = "t4g.micro" ] || {
  echo "FAIL: expected the arm64 default t4g.micro, got $instance_type" >&2
  exit 1
}

echo "OK: arm64"
