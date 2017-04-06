#!/usr/bin/env bash

# Configures the local (host) machine for passwordless sudo.
#
# This allows vagrant-hostmanager to modify /etc/hosts without entering the user's sudo password.
# Only the exact command used by vagrant-hostmanager is made passwordless.
# So this method is mildly more secure than global passwordless sudo.
#
# WARNING: ~/.vagrant.d/tmp/hosts.local can be used to hijack host resolution!
# This method is primarily intended for CI machines.
# Local users should avoid passwordless sudo for increased security.
#
# Usage:
# $ sudo ci/passwordless.sh

set -o errexit
set -o nounset
set -o pipefail

if [ "${EUID}" -ne 0 ]; then
  echo >&2 "Please run with sudo"
  exit 1
fi

if ! echo "${OSTYPE}" | grep -q 'darwin'; then
  echo >&2 "Incompatible OS - ${OSTYPE}"
  exit 1
fi

USER_GROUP_ID="$(stat -f '%g' "${BASH_SOURCE}")"
USER_GROUP="$(dscacheutil -q group -a gid ${USER_GROUP_ID} | grep name | cut -d ' ' -f 2)"
echo >&2 "User Group: ${USER_GROUP}"

ROOT_GROUP_ID="$(stat -f '%g' /etc/sudoers)"
ROOT_GROUP="$(dscacheutil -q group -a gid ${ROOT_GROUP_ID} | grep name | cut -d ' ' -f 2)"
echo >&2 "Root Group: ${ROOT_GROUP}"

if [[ ! -d /etc/sudoers.d ]]; then
  echo >&2 "Creating /etc/sudoers.d"
  mkdir -p /etc/sudoers.d
fi

if ! cat /etc/sudoers | grep -q '#includedir /etc/sudoers.d'; then
  echo >&2 "Updating /etc/sudoers to include /etc/sudoers.d"
  tee -a /etc/sudoers << EOF
#includedir /etc/sudoers.d
EOF
fi

if ! cat /etc/sudoers.d/vagrant_hostmanager | grep -q 'VAGRANT_HOSTMANAGER_UPDATE'; then
  echo >&2 "Creating /etc/sudoers.d/vagrant_hostmanager"
  tee /etc/sudoers.d/vagrant_hostmanager << EOF
Cmnd_Alias VAGRANT_HOSTMANAGER_UPDATE = /bin/cp ${HOME}/.vagrant.d/tmp/hosts.local /etc/hosts
%${USER_GROUP} ALL=(root) NOPASSWD: VAGRANT_HOSTMANAGER_UPDATE
EOF

  echo >&2 "Updating permissions on /etc/sudoers.d/vagrant_hostmanager"
  chmod 0440 /etc/sudoers.d/vagrant_hostmanager
  chown root:${ROOT_GROUP} /etc/sudoers.d/vagrant_hostmanager
fi
