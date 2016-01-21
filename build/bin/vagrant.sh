#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Saving box build time"
date > /etc/vagrant_box_build_time

echo ">>> Installing default vagrant ssh key"
mkdir -pm 700 /home/vagrant/.ssh
curl -L https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
