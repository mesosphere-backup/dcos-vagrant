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

if [[ -n "${LOG_LINES:-}" ]]; then
  LOG_LINES_ARG="-n=${LOG_LINES}"
else
  LOG_LINES_ARG=""
fi

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
export DCOS_MACHINE_CONFIG_PATH='VagrantConfig-1m-2a-1p.yaml'

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

# Log dependency versions
vagrant --version
vagrant plugin list
"$(ci/find-vboxmanage.sh)" --version
jq --version

# Destroy All VMs
ci/cleanup.sh

# Destroy All VMs on exit
function cleanup() {
  ci/dcos-logs.sh ${LOG_LINES_ARG} || true
  ci/cleanup.sh
}
trap cleanup EXIT

# Ensure latest dcos-vagrant-box
vagrant box update

# Deploy
vagrant up

DCOS_ADDRESS=m1.dcos

# Test API (unauthenticated)
curl --fail --location --silent --show-error --verbose http://${DCOS_ADDRESS}/dcos-metadata/dcos-version.json

# Install CLI
DCOS_CLI="$(ci/dcos-install-cli.sh)"
echo "${DCOS_CLI}"

# Delete CLI on exit
function cleanup2() {
  # Only use sudo if required
  if [[ -w "$(dirname "${DCOS_CLI}")" ]]; then
    rm -rf "${DCOS_CLI}"
  else
    sudo rm -rf "${DCOS_CLI}"
  fi
  cleanup
}
trap cleanup2 EXIT

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

# Add test user (required to be added when not the first user)
# TODO: only required for OSS DC/OS
ci/dcos-create-user.sh "albert@bekstil.net"

# Integration tests
ci/test-integration.sh
