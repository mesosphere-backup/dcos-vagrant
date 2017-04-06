#!/usr/bin/env bash

# Installs the cli to `<repo-root>/.cli/dcos` and configures to http://m1.dcos/.
#
# Options:
#   DCOS_VERSION (defaults to the "latest" in dcos-versions.yaml)
#
# Usage:
# $ ci/dcos-install-cli.sh
#
# CLI Usage:
# $ dcos --version
#
# Alt Usage:
# $ EXE="$(ci/dcos-install-cli.sh 2>/dev/null)"
# $ ${EXE} --version

set -o errexit
set -o nounset
set -o pipefail

DCOS_VERSION_LATEST="$(cat dcos-versions.yaml | grep '^latest' | cut -d "'" -f 2)"
DCOS_VERSION="${DCOS_VERSION:-${DCOS_VERSION_LATEST}}"
DCOS_CLI_VERSION="dcos-${DCOS_VERSION%.*}" # strip last version segment

case "${OSTYPE}" in
  darwin*)  PLATFORM='darwin/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  linux*)   PLATFORM='linux/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  msys*)    PLATFORM='windows/x86-64'; BIN='${HOME}/AppData/Local/Microsoft/WindowsApps'; EXE='dcos.exe' ;;
  *)        echo >&2 "Unsupported operating system: ${OSTYPE}"; exit 1 ;;
esac

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

echo >&2 "Downloading CLI..."
curl -O https://downloads.dcos.io/binaries/cli/${PLATFORM}/${DCOS_CLI_VERSION}/${EXE}

echo >&2 "Installing CLI..."
chmod +x "${EXE}"
mv "${EXE}" "${BIN}/"

echo >&2 "Configuring CLI..."
DCOS_URL="http://m1.dcos/"
dcos config set core.dcos_url "${DCOS_URL}"

# Log CLI & Cluster versions
dcos --version >&2

echo >&2 "Location:"
echo "${BIN}/${EXE}"
