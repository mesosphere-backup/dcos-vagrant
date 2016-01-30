#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing packages (perl tar xz unzip curl bind-utils)"
yum install --assumeyes --tolerant perl tar xz unzip curl bind-utils net-tools

echo ">>> Caching docker image: jplock/zookeeper"
docker pull jplock/zookeeper

echo ">>> Caching docker image: nginx"
docker pull nginx

echo ">>> Creating ~/dcos"
mkdir -p ~/dcos && cd ~/dcos
