#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> New Kernel: $(uname -r)"

echo ">>> Creating docker group"
/usr/sbin/groupadd -f docker

echo ">>> Installing packages (docker)"
yum install --assumeyes --tolerant docker

echo ">>> Enabling docker on boot"
systemctl enable docker

echo ">>> Disabling firewalld"
#systemctl stop firewalld
systemctl disable firewalld

echo ">>> Starting docker"
#docker daemon -D -l debug --storage-opt dm.no_warn_on_loop_devices=true 
service docker start && sleep 30
while [ `service docker status | grep "active (running)" --count` -lt 1 ]
do
	echo ">>> Docker not available ... retrying [" date "]"
	service docker start && sleep 30
done

