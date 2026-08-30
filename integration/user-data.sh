#!/bin/sh
# Run by cloud-init at boot. Referenced by the user-data suite as a path, so
# reading and base64 encoding the file is part of what that suite proves.
echo "kitchen-ec2 integration $(date -u +%FT%TZ)" > /var/tmp/kitchen-ec2-user-data
