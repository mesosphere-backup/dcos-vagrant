#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

yum -y erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all
rm -rf VBoxGuestAdditions_*.iso
rm -rf /tmp/rubygems-*

