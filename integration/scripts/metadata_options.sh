#!/bin/sh
# metadata_options is forwarded to RunInstances verbatim. Asking the metadata
# service itself is the only way to know EC2 applied it.
set -eu

# http_tokens: required means an unauthenticated IMDSv1 read must be refused.
if curl -sSf --max-time 5 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
  echo "FAIL: IMDSv1 still answers, so http_tokens: required was not applied" >&2
  exit 1
fi
echo "IMDSv1: refused, as configured"

TOKEN=$(curl -sSf -X PUT http://169.254.169.254/latest/api/token \
  -H 'X-aws-ec2-metadata-token-ttl-seconds: 120')
imds() {
  curl -sSf -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$1"
}

echo "instance-id: $(imds instance-id)"

# instance_metadata_tags: enabled is what makes this readable at all, so the
# whole block took effect -- and it is the only way to see from the instance
# that the driver's tags reached EC2.
tags=$(imds tags/instance || true)
echo "tags: $(echo "$tags" | tr '\n' ' ')"

echo "$tags" | grep -qx 'created-by' || {
  echo "FAIL: the created-by tag is not readable; tags did not reach the instance" >&2
  exit 1
}

[ "$(imds tags/instance/created-by)" = "test-kitchen" ] || {
  echo "FAIL: created-by is not test-kitchen" >&2
  exit 1
}

echo "OK: metadata-options"
