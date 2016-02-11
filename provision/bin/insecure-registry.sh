#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Registering private docker registry: boot.dcos:5000"
sed -i -e "s/OPTIONS='/OPTIONS='--insecure-registry boot.dcos:5000 /" /etc/sysconfig/docker
systemctl restart docker
