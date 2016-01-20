#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing DCOS slave"
curl -s http://boot.dcos/dcos_install.sh | bash -s -- slave
