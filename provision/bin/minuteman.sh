#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Setting path"
export PATH=/opt/erlang-18.2.1/bin:$PATH
echo $PATH

echo ">>> Cloning minuteman"
cd /opt
git clone git@github.com:mesosphere/minuteman.git -b rebar3

echo ">>> Compiling minuteman"
cd /opt/minuteman
make

echo ">>> Building release"
make rel
