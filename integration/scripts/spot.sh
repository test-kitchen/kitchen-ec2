#!/bin/sh
# A spot request that quietly fell back to an on-demand launch looks exactly
# like a success from the outside: an instance exists and Test Kitchen connects
# to it. The instance reports its own lifecycle, which is the difference.
set -eu

TOKEN=$(curl -sSf -X PUT http://169.254.169.254/latest/api/token \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 120')
lifecycle=$(curl -sSf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-life-cycle)

echo "instance-life-cycle: $lifecycle"

[ "$lifecycle" = "spot" ] || {
  echo "FAIL: expected a spot instance, got $lifecycle" >&2
  exit 1
}

echo "OK: spot"
