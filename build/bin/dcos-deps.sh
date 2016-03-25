#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Adding group [nogroup]"
/usr/sbin/groupadd -f nogroup

echo ">>> Installing packages (perl tar xz unzip curl bind-utils ipset)"
yum install --assumeyes --tolerant perl tar xz unzip curl bind-utils net-tools ipset

echo ">>> Creating ~/dcos"
mkdir -p ~/dcos && cd ~/dcos
