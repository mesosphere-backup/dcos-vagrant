#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Setting path"
export PATH=/opt/erlang-18.2.1/bin:$PATH
echo $PATH

echo ">>> Installing ipset"
yum install --assumeyes --tolerant ipset

echo ">>> Cloning minuteman"
cd /tmp
git clone git@github.com:mesosphere/minuteman.git -b rebar3

echo ">>> Compiling and building release of minuteman"
cd /tmp/minuteman
make rel

echo ">>> Installing release"
cp -r /tmp/minuteman/_build/default/rel/minuteman /opt/minuteman

