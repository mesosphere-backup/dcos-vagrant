#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Adding boot.dcos:5000 as an insecure docker registry."
sed -i -e "s/OPTIONS='/OPTIONS='--insecure-registry boot.dcos:5000 /" /etc/sysconfig/docker
systemctl restart docker
