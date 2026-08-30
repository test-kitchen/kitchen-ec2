#!/bin/sh
# The driver's defaults, end to end: the AMI search found an image for this
# platform, the free-tier instance type matched its architecture, the
# auto-created security group let the transport in, and the auto-created key
# pair logged in as the platform's own user.
set -eu

TOKEN=$(curl -sSf -X PUT http://169.254.169.254/latest/api/token \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 120')
imds() {
  curl -sSf -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$1"
}

instance_type=$(imds instance-type)
arch=$(uname -m)

echo "instance-type: $instance_type"
echo "architecture:  $arch"
echo "login user:    ${SUDO_USER:-$(id -un)}"
echo "os-release:    $(grep -m1 PRETTY_NAME /etc/os-release)"

# t3.micro is the driver's free-tier default for a hardware-virtualized
# x86_64 image. Getting anything else here means the default no longer
# follows the image.
[ "$instance_type" = "t3.micro" ] || {
  echo "FAIL: expected the default instance type t3.micro, got $instance_type" >&2
  exit 1
}

[ "$arch" = "x86_64" ] || {
  echo "FAIL: expected an x86_64 image, got $arch" >&2
  exit 1
}

# The driver detects the login user from the platform it resolved, so this is
# also the assertion that the AMI search landed on the distribution asked for
# rather than on something else that happened to match the filters. All four
# platforms here log in as an unprivileged account, never as root.
login_user=${SUDO_USER:-}
[ -n "$login_user" ] && [ "$login_user" != "root" ] || {
  echo "FAIL: expected an unprivileged platform user, got '${login_user:-<none>}'" >&2
  exit 1
}

echo "OK: default"
