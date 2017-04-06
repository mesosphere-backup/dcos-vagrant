#!/usr/bin/env bash

# Performs End To End (e2e) testing of DC/OS Vagrant.
#
# Options:
#   DCOS_VERSION (defaults to the "latest" in dcos-versions.yaml)
#
# Usage:
# $ ci/test-e2e.sh

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Require bash 4+ for associative arrays
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "Requires Bash 4+" >&2
  exit 1
fi

# Default to latest known version unless DCOS_VERSION is specified
if [[ -z "${DCOS_VERSION:-}" ]]; then
  export DCOS_VERSION="$(cat dcos-versions.yaml | grep '^latest' | cut -d "'" -f 2)"
fi

# Minimal config
export DCOS_MACHINE_CONFIG_PATH='VagrantConfig-1m-1a-1p.yaml'

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

# Log dependency versions
vagrant --version
vagrant plugin list
VBoxManage --version
jq --version

# Destroy All VMs
ci/cleanup.sh

# Destroy All VMs on exit
trap 'ci/cleanup.sh' EXIT

# Deploy
vagrant up

DCOS_ADDRESS=m1.dcos

# Test API (unauthenticated)
curl --fail --location --silent --show-error --verbose http://${DCOS_ADDRESS}/dcos-metadata/dcos-version.json

# Install CLI
ci/dcos-install-cli.sh

# Delete CLI on exit
trap 'rm -rf "$(pwd)/.cli"; ci/cleanup.sh' EXIT

# Create User
DCOS_USER="test@example.com"
ci/dcos-create-user.sh "${DCOS_USER}"

# Login
DCOS_ACS_TOKEN="$(ci/dcos-login.sh "${DCOS_USER}")"
dcos config set core.dcos_acs_token "${DCOS_ACS_TOKEN}"

# Install & test Oinker
ci/test-oinker.sh

# Detect URL
DCOS_URL="$(dcos config show core.dcos_url)"

# Test GUI (authenticated)
curl --fail --location --silent --show-error --verbose -H "Authorization: token=${DCOS_ACS_TOKEN}" ${DCOS_URL} -o /dev/null
