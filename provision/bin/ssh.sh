#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing required packages..."
sudo yum install --assumeyes --tolerant git

echo ">>> Configuring ssh..."
# Taken from https://github.com/mitchellh/vagrant/issues/1735.

# Enable ssh agent forwarding
touch /etc/sudoers.d/root_ssh_agent
chmod 0440 /etc/sudoers.d/root_ssh_agent
echo "Defaults    env_keep += \"SSH_AUTH_SOCK\"" > /etc/sudoers.d/root_ssh_agent

if [ -z "$SSH_AUTH_SOCK" ]; then
  echo "ssh agent not forwarded, aborting" >&2
  exit 1
fi

# Make these known hosts to ssh
# ssh -T git@bitbucket.org -o StrictHostKeyChecking=no
ssh -T git@github.com -o StrictHostKeyChecking=no || true

# Installation of some deps as an unprivileged user require correct
# permissions.
/bin/chmod 755 /etc/pki/tls/certs

# Force exit of 0
exit 0
