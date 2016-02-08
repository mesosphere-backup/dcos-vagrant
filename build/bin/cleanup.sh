#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub

echo ">>> Cleaning Ruby Gems"
rm -rf /tmp/rubygems-*
