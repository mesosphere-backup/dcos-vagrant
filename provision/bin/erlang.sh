#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing required packages..."
yum install --assumeyes --tolerant wget ncurses-devel openssl-devel gcc make

echo ">>> Downloading Erlang 18.2.1..."
cd /tmp
wget http://erlang.org/download/otp_src_18.2.1.tar.gz

echo ">>> Compiling Erlang 18.2.1..."
gzip -dc otp_src_18.2.1.tar.gz | tar -xvf -
cd otp_src_18.2.1
./configure --prefix=/opt/erlang-18.2.1 --enable-smp-support --with-ssl
make
make install
