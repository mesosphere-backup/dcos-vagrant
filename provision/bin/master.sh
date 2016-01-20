#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing DCOS master"
curl -s http://boot.dcos/dcos_install.sh | bash -s -- master
