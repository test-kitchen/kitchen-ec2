#!/bin/sh
# Block device mappings are passed to RunInstances untouched, so the only way
# to know they were accepted in the shape the driver sent them is to look at
# the disks the instance actually booted with.
set -eu

lsblk -b -d -n -o NAME,SIZE || true

# Root volume was asked for at 30 GiB. Compared as a range because the
# filesystem and the partition table both take a little off the top.
root_dev=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//; s|/dev/||')
root_bytes=$(lsblk -b -d -n -o SIZE "/dev/${root_dev}")
root_gb=$((root_bytes / 1024 / 1024 / 1024))
echo "root volume: ${root_gb}G on ${root_dev}"

[ "$root_gb" -ge 29 ] && [ "$root_gb" -le 31 ] || {
  echo "FAIL: expected a 30G root volume, got ${root_gb}G" >&2
  exit 1
}

# The second mapping attaches an unformatted 20 GiB volume. Linux renames
# /dev/sdf to /dev/xvdf or an NVMe name depending on the instance family, so
# this looks for a disk of the right size rather than a device name.
extra=$(lsblk -b -d -n -o NAME,SIZE | awk '{ gb = $2 / 1024 / 1024 / 1024; if (gb >= 19 && gb <= 21) print $1 }')
echo "extra volume: ${extra:-<none>}"

[ -n "$extra" ] || {
  echo "FAIL: the extra 20G volume from block_device_mappings is not attached" >&2
  exit 1
}

echo "OK: block-devices"
