#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# yum makecache fast

yum install --assumeyes --tolerant docker
#echo ">>> Added packages (gcc make gcc-c++ kernel-devel* perl tar xz unzip curl docker bind-utils)"

/usr/sbin/groupadd -f docker
/usr/sbin/usermod -aG docker vagrant
echo ">>> Created groups (docker) and adding to user."

#yum upgrade --assumeyes --tolerant
#echo ">>> Upgraded OS"

yum install --assumeyes --tolerant gcc make gcc-c++ kernel-devel-`uname -r`

systemctl enable docker
echo ">>> Enabling docker"

service docker restart
echo ">>> Starting docker and running (docker ps)"
docker ps

sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
echo ">>> Disabled SELinux and adjusted sudoers"

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
echo ">>> Disabled IPV6"

mkdir -p ~/dcos && cd ~/dcos
echo ">>> Disabled IPV6"

docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 jplock/zookeeper
echo ">>> Creating docker service (jplock/zookeeper) for exhibitor bootstrap and quorum."

docker run -d -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 nginx
echo ">>> Creating docker service (nginx) for ease of distributing bootstrap artificats to cluster."

docker ps
