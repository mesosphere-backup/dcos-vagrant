#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

VBOX_VERSION=$(cat /home/vagrant/.vbox_version)

# required for VirtualBox 4.3.26
#yum install --assumeyes --tolerant bzip2

cd /tmp
mount -o loop /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
# TODO: fix OpenGL support module installation
sh /mnt/VBoxLinuxAdditions.run || true
umount /mnt
rm -rf /home/vagrant/VBoxGuestAdditions_*.iso

