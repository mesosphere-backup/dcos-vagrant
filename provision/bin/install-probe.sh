#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if hash probe 2>/dev/null; then
  echo "Probe already installed: $(which probe)"
  exit 0
fi

echo ">>> Installing probe: /usr/local/sbin/probe"
curl -sL https://github.com/karlkfi/probe/releases/download/v0.3.0/probe-0.3.0-linux_amd64.tgz | tar zxf - -C /usr/local/sbin/
