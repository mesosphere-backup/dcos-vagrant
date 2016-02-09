#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

MASTER_IP=192.168.65.90

echo $(/usr/sbin/ip route show to match ${MASTER_IP} | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)

