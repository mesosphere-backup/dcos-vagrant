#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# yum makecache fast

echo ">>> Installing packages (docker)"
yum install --assumeyes --tolerant docker

/usr/sbin/groupadd -f docker
/usr/sbin/usermod -aG docker vagrant
echo ">>> Created groups (docker) and adding to user."

#yum upgrade --assumeyes --tolerant
#echo ">>> Upgraded OS"

echo ">>> Installing packages (gcc make gcc-c++ kernel-devel*)" # perl tar xz unzip curl bind-utils
yum install --assumeyes --tolerant gcc make gcc-c++ kernel-devel-$(uname -r)

echo ">>> Enabling docker"
systemctl enable docker

echo ">>> Starting docker"
service docker restart

echo ">>> Listing running docker containers"
docker ps

echo ">>> Disabling SELinux and adjusted sudoers"
sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

echo ">>> Disabling IPV6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

echo ">>> Creating ~/dcos"
mkdir -p ~/dcos && cd ~/dcos

echo ">>> Creating docker service (jplock/zookeeper) for exhibitor bootstrap and quorum."
docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 jplock/zookeeper

echo ">>> Creating docker service (nginx) for ease of distributing bootstrap artificats to cluster."
docker run -d -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 nginx

echo ">>> Listing running docker containers"
docker ps
