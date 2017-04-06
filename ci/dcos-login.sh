#!/usr/bin/env bash

# Generates a JWT (token) for a user using the dcos-oauth private key.
# Technically, this bypasses the login API and authentication provider.
# This method is only for testing and should not be used in production!
#
# Usage:
# $ ci/dcos-login.sh <user-email>
#
# Configure CLI:
# $ DCOS_ACS_TOKEN="$(ci/dcos-login.sh "${DCOS_USER}")"
# $ dcos config set core.dcos_acs_token "${DCOS_ACS_TOKEN}"

set -o errexit
set -o nounset
set -o pipefail

if [[ -z "${1:-}" ]]; then
  echo >&2 'User email required'
  exit 2
fi

VAGRANT_LOG=error vagrant ssh m1 << EOM
docker run --rm \
    -v /var/lib/dcos/dcos-oauth/auth-token-secret:/key \
    karlkfi/jwt-encoder ${1} /key --duration=86400 #24hrs
EOM
