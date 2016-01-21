#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Cleaning yum"
yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

echo ">>> Cleaning VBoxGuestAdditions"
rm -rf VBoxGuestAdditions_*.iso

echo ">>> Cleaning Ruby Gems"
rm -rf /tmp/rubygems-*
