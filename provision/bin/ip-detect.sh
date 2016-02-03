#!/bin/sh
set -o nounset -o errexit

mkdir -p ~/dcos/genconf

cat << EOF > ~/dcos/genconf/ip-detect
#!/usr/bin/env bash
set -o nounset -o errexit

echo \$(/usr/sbin/ip route show to match $MASTER_IP | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)

EOF
