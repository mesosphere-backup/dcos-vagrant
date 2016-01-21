#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Enabling docker"
systemctl enable docker

echo ">>> Starting docker and running (docker ps)"
service docker restart
docker ps

echo ">>> Creating ~/dcos"
mkdir -p ~/dcos && cd ~/dcos
