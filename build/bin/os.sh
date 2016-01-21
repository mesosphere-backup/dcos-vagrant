#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# caching doesn't speed up one-time installation
# yum makecache fast

echo ">>> Old Kernel: $(uname -r)"
echo ">>> Upgrading OS"
yum upgrade --assumeyes --tolerant
yum update --assumeyes
echo ">>> New Kernel: $(uname -r)"

echo ">>> Rebooting to upgrade kernel"
reboot
