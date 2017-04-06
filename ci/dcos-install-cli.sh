#!/usr/bin/env bash

# Installs the cli and configures the DC/OS URL.
#
# Options:
#   DCOS_VERSION (defaults to the "latest" in dcos-versions.yaml)
#
# Usage:
# $ ci/dcos-install-cli.sh
#
# Remote Usage:
# $ curl https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-install-cli.sh | bash
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

# Default to dcos-vagrant address
export DCOS_URL="${DCOS_URL:-http://m1.dcos/}"

if [[ -z "${DCOS_VERSION:-}" ]]; then
  # Find version detection script
  if [[ -z "${DCOS_VERSION_DETECT:-}" ]]; then
    if [[ -f 'ci/dcos-version.sh' ]]; then
      DCOS_VERSION_DETECT="file://${PWD}/ci/dcos-version.sh"
    else
      # support curl | bash
      DCOS_VERSION_DETECT='https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-version.sh'
    fi
  fi

  echo >&2 "Version detect script: ${DCOS_VERSION_DETECT}"

  # Detect version
  DCOS_VERSION="$(curl --fail --location --silent --show-error "${DCOS_VERSION_DETECT}" | bash)"
fi

echo >&2 "DC/OS Version: ${DCOS_VERSION}"

# Get major version by stripping the last version segment
DCOS_MAJOR_VERSION="${DCOS_VERSION%.*}"
echo >&2 "DC/OS Major Version: ${DCOS_MAJOR_VERSION}"

case "${OSTYPE}" in
  darwin*)  PLATFORM='darwin/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  linux*)   PLATFORM='linux/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  msys*)    PLATFORM='windows/x86-64'; BIN='${HOME}/AppData/Local/Microsoft/WindowsApps'; EXE='dcos.exe' ;;
  *)        echo >&2 "Unsupported operating system: ${OSTYPE}"; exit 1 ;;
esac

echo >&2 "Downloading CLI..."
curl --fail --location --silent --show-error -O https://downloads.dcos.io/binaries/cli/${PLATFORM}/dcos-${DCOS_MAJOR_VERSION}/${EXE}

echo >&2 "Installing CLI..."
chmod a+x "${EXE}"
mv "${EXE}" "${BIN}/"

echo >&2 "Configuring CLI..."
dcos config set core.dcos_url "${DCOS_URL}"

# Log CLI & Cluster versions
dcos --version >&2

echo >&2 "Location:"
echo "${BIN}/${EXE}"
