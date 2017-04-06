#!/usr/bin/env bash

# Creates a new dcos-oauth user.
# Technically, this bypasses the login API and authentication provider.
# This method is only for testing and should not be used in production!
#
# Usage:
# $ ci/dcos-create-user.sh <user-email>

set -o errexit
set -o nounset
set -o pipefail

if [[ -z "${1:-}" ]]; then
  echo >&2 'User email required'
  exit 2
fi

VAGRANT_LOG=error vagrant ssh m1 << EOM
source /opt/mesosphere/environment.export
python /opt/mesosphere/active/dcos-oauth/bin/dcos_add_user.py ${1}
EOM
