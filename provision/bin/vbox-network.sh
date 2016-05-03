#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if VBoxManage list hostonlyifs | grep 'IPAddress:.*192.168.65.1' -q; then
  # compatible VirtualBox network found
  exit 0
fi

echo ">>> Creating VirtualBox Network"
network_name="$(VBoxManage hostonlyif create | grep "successfully created" | sed "s/Interface '\(.*\)' was successfully created/\1/")"
echo "Network Created: '${network_name}'"

echo ">>> Configuring network '${network_name}' to use 192.168.65.0\24"
VBoxManage hostonlyif ipconfig --ip 192.168.65.1 "${network_name}"
