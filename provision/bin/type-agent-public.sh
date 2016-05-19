#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! curl --fail --location --silent --show-error http://boot.dcos/dcos_install.sh > /dev/null; then
  echo ">>> Bootstrap machine unreachable - postponing DC/OS slave install"
  exit 0
fi

echo ">>> Installing DC/OS slave_public"
curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public
