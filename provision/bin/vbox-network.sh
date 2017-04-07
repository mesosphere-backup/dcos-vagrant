#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/../.." && pwd -P)
cd "${project_dir}"

VBM="$(ci/find-vboxmanage.sh)"

if ! "${VBM}" list hostonlyifs | grep 'IPAddress:\s*192.168.65.1' -q; then
  # no compatible Host-Only network found
  echo ">>> Creating VirtualBox Host-Only Network"
  network_name="$("${VBM}" hostonlyif create | grep "successfully created" | sed "s/Interface '\(.*\)' was successfully created/\1/")"
  echo "Host-Only Network Created: '${network_name}'"

  echo ">>> Configuring Host-Only network '${network_name}' to use 192.168.65.0\24"
  "${VBM}" hostonlyif ipconfig --ip 192.168.65.1 "${network_name}"
  echo "Host-Only Network Configured: '${network_name}' (192.168.65.0\24)"
fi
