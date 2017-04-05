#!/usr/bin/env bash

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
