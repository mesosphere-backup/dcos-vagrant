#!/usr/bin/env bash

# Installs the cli to `<repo-root>/.cli/dcos` and configures to http://m1.dcos/.
# WARNING: Mac-Only (for now)
#
# CLI Usage:
# $ PATH="$(pwd)/.cli:$PATH"
# $ dcos --version

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Mac-Only (for now)
if ! echo "${OSTYPE}" | grep -q 'darwin'; then
  echo >&2 "Incompatible OS - ${OSTYPE}"
  exit 1
fi

if [[ -z "${DCOS_VERSION:-}" ]]; then
  echo "DCOS_VERSION required" >&2
  exit 2
fi

DCOS_CLI_VERSION="dcos-${DCOS_VERSION%.*}" # strip last version segment

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

# Install CLI
curl -O https://downloads.dcos.io/binaries/cli/darwin/x86-64/${DCOS_CLI_VERSION}/dcos
chmod +x dcos
CLI_DIR="$(pwd)/.cli"
mkdir -p "${CLI_DIR}"
mv dcos "${CLI_DIR}/"
PATH="${CLI_DIR}:$PATH"

# Configure CLI
DCOS_URL="http://m1.dcos/"
dcos config set core.dcos_url "${DCOS_URL}"

# Log CLI & Cluster versions
dcos --version
