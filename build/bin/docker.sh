#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> New Kernel: $(uname -r)"

echo ">>> Installing Docker"
curl -fsSL https://get.docker.com/ | sh

echo ">>> Creating docker group"
/usr/sbin/groupadd -f docker

echo ">>> Enabling docker on boot"
chkconfig docker on

echo ">>> Disabling firewalld"
systemctl disable firewalld

echo ">>> Customizing Docker storage driver"
docker_service_d=/etc/systemd/system/docker.service.d
mkdir -p "$docker_service_d"
cat << 'EOF' > "${docker_service_d}/execstart.conf"
[Service]
ExecStartPre=/bin/sh -ec "until df|grep /mnt;do echo waiting for /mnt;sleep 10;done"
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --graph=/mnt/docker --storage-driver=overlay
EOF
