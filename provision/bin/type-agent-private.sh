#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! probe tcp://boot.dcos:80; then
  >&2 echo "Bootstrap machine unreachable - postponing DC/OS slave install"
  exit 0
fi

echo ">>> Installing DC/OS slave"
curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave
