#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing packages (gcc make gcc-c++ kernel-devel* kernel-headers* dkms)"
yum install --assumeyes --tolerant gcc make gcc-c++ kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms

VBOX_VERSION=$(cat /home/vagrant/.vbox_version)

# required for VirtualBox 4.3.26
#yum install --assumeyes --tolerant bzip2

echo ">>> Installing VBoxGuestAdditions ${VBOX_VERSION}"
cd /tmp
mount -o loop /home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
# TODO: fix OpenGL support module installation
sh /mnt/VBoxLinuxAdditions.run || true
umount /mnt
rm -rf /home/vagrant/VBoxGuestAdditions_*.iso

echo ">>> Configuring VBox modules to load on boot"
# support reboots
cat > /etc/modules-load.d/virtualbox.conf << EOF
vboxguest
vboxsf
vboxvideo
EOF
