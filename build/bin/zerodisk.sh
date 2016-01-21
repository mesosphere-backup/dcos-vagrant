#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Zeroing /dev/zero"
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
