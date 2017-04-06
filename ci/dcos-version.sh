#!/usr/bin/env bash

# Detects the version of an existing DC/OS cluster
#
# Options:
#   DCOS_URL (default: http://m1.dcos/)
#
# Usage:
# $ DCOS_VERSION="$(ci/dcos-version.sh)"
#
# Remote Usage:
# $ curl https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-version.sh | bash

set -o errexit
set -o nounset
set -o pipefail

# Default to dcos-vagrant address
DCOS_URL="${DCOS_URL:-http://m1.dcos/}"

# Auto-detect version (unauthenticated)
DCOS_VERSION_META="$(curl --fail --location --silent --show-error ${DCOS_URL%/}/dcos-metadata/dcos-version.json)"

# Extract version from metadata
DCOS_VERSION="$(echo "${DCOS_VERSION_META}" | grep 'version' | cut -d ':' -f 2 | cut -d '"' -f 2)"

echo "${DCOS_VERSION}"
