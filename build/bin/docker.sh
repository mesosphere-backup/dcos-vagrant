#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing packages (docker)"
yum install --assumeyes --tolerant docker

echo ">>> Creating docker group and adding vagrant user to it"
/usr/sbin/groupadd -f docker
/usr/sbin/usermod -aG docker vagrant

echo ">>> Enabling docker on boot"
systemctl enable docker

echo ">>> Starting docker"
service docker restart

echo ">>> Disabling SELinux and adjusted sudoers"
sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

echo ">>> Disabling IPV6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
