#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# caching doesn't speed up one-time installation
# yum makecache fast

echo ">>> Old Kernel: $(uname -r)"
echo ">>> Upgrading OS"
yum upgrade --assumeyes --tolerant
yum update --assumeyes

echo ">>> Disabling SELinux and adjusted sudoers"
sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

echo ">>> Disabling IPV6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

echo ">>> Rebooting to upgrade kernel"
shutdown -r now && sleep 5
