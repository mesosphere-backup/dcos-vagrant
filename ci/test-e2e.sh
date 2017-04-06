#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Require bash 4+ for associative arrays
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "Requires Bash 4+" >&2
  exit 1
fi

DCOS_VERSION_LATEST="$(cat dcos-versions.yaml | grep '^latest' | cut -d "'" -f 2)"
export DCOS_VERSION="${DCOS_VERSION:-${DCOS_VERSION_LATEST}}"
DCOS_CLI_VERSION="dcos-${DCOS_VERSION%.*}" # strip last version segment
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
trap 'ci/cleanup.sh' EXIT

# Deploy
vagrant up

DCOS_ADDRESS=m1.dcos

# Test API (unauthenticated)
curl --fail --location --silent --show-error --verbose http://${DCOS_ADDRESS}/dcos-metadata/dcos-version.json

# Install CLI
curl -O https://downloads.dcos.io/binaries/cli/darwin/x86-64/${DCOS_CLI_VERSION}/dcos
chmod +x dcos
CLI_DIR="$(pwd)/.cli"
mkdir -p "${CLI_DIR}"
mv dcos "${CLI_DIR}/"
PATH="${CLI_DIR}:$PATH"
trap 'rm -rf "${CLI_DIR}"; ci/cleanup.sh' EXIT

# Configure CLI
DCOS_URL="http://${DCOS_ADDRESS}/"
dcos config set core.dcos_url "${DCOS_URL}"

# Log CLI & Cluster versions
dcos --version

# Create User
DCOS_USER="test@example.com"
ci/dcos-create-user.sh "${DCOS_USER}"

# Login
DCOS_ACS_TOKEN="$(ci/dcos-login.sh "${DCOS_USER}")"
dcos config set core.dcos_acs_token "${DCOS_ACS_TOKEN}"

# Install & test Oinker
ci/test-oinker.sh

# Test GUI
curl --fail --location --silent --show-error --verbose -H "Authorization: token=${DCOS_ACS_TOKEN}" ${DCOS_URL} -o /dev/null
