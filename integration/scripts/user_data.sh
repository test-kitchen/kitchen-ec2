#!/bin/sh
# user_data naming a file is read from disk and base64 encoded before launch.
# Nothing about that is visible from the API, so the proof is that cloud-init
# ran the script on the instance.
set -eu

# The transport can be ready before cloud-init has finished, which would make
# this a race rather than an assertion.
cloud-init status --wait || true

marker=/var/tmp/kitchen-ec2-user-data

[ -f "$marker" ] || {
  echo "FAIL: user_data did not run; $marker was never written" >&2
  echo "--- cloud-init output ---" >&2
  tail -n 50 /var/log/cloud-init-output.log >&2 || true
  exit 1
}

echo "user_data wrote: $(cat "$marker")"

grep -q 'kitchen-ec2 integration' "$marker" || {
  echo "FAIL: $marker does not contain the expected content" >&2
  exit 1
}

echo "OK: user-data"
