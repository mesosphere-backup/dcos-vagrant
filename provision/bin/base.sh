#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Enabling docker"
systemctl enable docker

echo ">>> Starting docker"
service docker restart
