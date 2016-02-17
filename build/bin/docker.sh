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
systemctl disable firewalld

echo ">>> Stopping docker (to reconfigure)"
systemctl stop docker

echo ">>> Removing docker volumes (/var/lib/docker)"
rm -rf /var/lib/docker

echo ">>> Configuring docker (OverlayFS)"
echo "STORAGE_DRIVER=overlay" >> /etc/sysconfig/docker-storage-setup

sed -i "s/OPTIONS='--selinux-enabled'/OPTIONS='--selinux-enabled=false'/g" /etc/sysconfig/docker
sed -i "s/DOCKER_STORAGE_OPTIONS=/DOCKER_STORAGE_OPTIONS= -s overlay/" /etc/sysconfig/docker-storage

echo ">>> Starting docker"
systemctl start docker

echo ">>> Starting docker"
#docker daemon -D -l debug --storage-opt dm.no_warn_on_loop_devices=true 
service docker start && sleep 30
while [ `service docker status | grep "active (running)" --count` -lt 1 ]
do
	echo ">>> Docker not available ... retrying [" date "]"
	service docker start && sleep 30
done

