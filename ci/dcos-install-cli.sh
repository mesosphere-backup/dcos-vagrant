#!/usr/bin/env bash

# Installs and configures the DC/OS CLI.
#
# Auto-detects the DC/OS version by asking an existing DC/OS cluster.
# Auto-detects the local operating system to download the right DC/OS CLI binary.
#
# Options:
#   DCOS_URL -- URL to DC/OS cluster (default: http://m1.dcos/)
#   DCOS_VERSION -- Version of DC/OS (default: <auto-detected>)
#   DCOS_VERSION_DETECT -- URL of version detection script (default: file://${PWD}/ci/dcos-version.sh or https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-version.sh)
#
# Usage:
# $ ci/dcos-install-cli.sh
# $ dcos --version
#
# Alt Usage:
# $ EXE="$(ci/dcos-install-cli.sh 2>/dev/null)"
# $ ${EXE} --version
#
# Remote Usage:
# $ curl https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-install-cli.sh | bash
# $ dcos --version

set -o errexit
set -o nounset
set -o pipefail

# Default to dcos-vagrant address
export DCOS_URL="${DCOS_URL:-http://m1.dcos/}"

echo >&2 "DC/OS URL: ${DCOS_URL}"

if [[ -z "${DCOS_VERSION:-}" ]] && [[ -z "${DCOS_VERSION_DETECT:-}" ]] && [[ -f 'ci/dcos-version.sh' ]]; then
  # Default to local version detection script, if available.
  echo >&2 "Version detect script: ci/dcos-version.sh"
  DCOS_VERSION="$(ci/dcos-version.sh)"
fi

if [[ -z "${DCOS_VERSION:-}" ]]; then
  # Default to version remote detection script
  DCOS_VERSION_DETECT="${DCOS_VERSION_DETECT:-https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-version.sh}"
  echo >&2 "Version detect script: ${DCOS_VERSION_DETECT}"
  DCOS_VERSION="$(curl --fail --location --silent --show-error "${DCOS_VERSION_DETECT}" | bash)"
fi

echo >&2 "DC/OS Version: ${DCOS_VERSION}"

# Get major.minor version by stripping the patch version segment (if present)
DCOS_MAJOR_MINOR_VERSION="$(echo "${DCOS_VERSION}" | sed -e "s#[^0-9]*\([0-9][0-9]*[.][0-9][0-9]*\).*#\1#")"
echo >&2 "DC/OS Major Version: ${DCOS_MAJOR_MINOR_VERSION}"

case "${OSTYPE}" in
  darwin*)  PLATFORM='darwin/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  linux*)   PLATFORM='linux/x86-64'; BIN='/usr/local/bin'; EXE='dcos' ;;
  msys*)    PLATFORM='windows/x86-64'; BIN="${HOME}/AppData/Local/Microsoft/WindowsApps"; EXE='dcos.exe' ;;
  *)        echo >&2 "Unsupported operating system: ${OSTYPE}"; exit 1 ;;
esac

TMPDIR="${TMPDIR:-/tmp/}"
CLI_DIR="$(mktemp -d "${TMPDIR%/}/dcos-install-cli.XXXXXXXXXXXX")"
trap "rm -rf ${CLI_DIR}" EXIT

DCOS_CLI_URL="https://downloads.dcos.io/binaries/cli/${PLATFORM}/dcos-${DCOS_MAJOR_MINOR_VERSION}/${EXE}"
echo >&2 "Download URL: ${DCOS_CLI_URL}"
echo >&2 "Download Path: ${CLI_DIR}/${EXE}"
curl --fail --location --silent --show-error -o "${CLI_DIR}/${EXE}" "${DCOS_CLI_URL}"

echo >&2 "Install Path: ${BIN}/${EXE}"
chmod a+x "${CLI_DIR}/${EXE}"
# only use sudo if required
if [[ -w "${BIN}" ]]; then
  mv "${CLI_DIR}/${EXE}" "${BIN}/"
else
  sudo mv "${CLI_DIR}/${EXE}" "${BIN}/"
fi
rm -rf ${CLI_DIR}

# 1.10 changed the auth commands
DCOS_MAJOR_VERSION="$(echo "${DCOS_MAJOR_MINOR_VERSION}" | cut -d'.' -f1)"
DCOS_MINOR_VERSION="$(echo "${DCOS_MAJOR_MINOR_VERSION}" | cut -d'.' -f2)"
if [[ "${DCOS_MAJOR_VERSION}" -ge "1" ]] && [[ "${DCOS_MINOR_VERSION}" -ge "10" ]]; then
  # >= 1.10
  CLUSTER_ID="$(curl --fail --location --silent --show-error ${DCOS_URL}/dcos-metadata/ui-config.json | jq -e -r .clusterConfiguration.id)"
  mkdir -p ~/.dcos/clusters/${CLUSTER_ID}
  cat > ~/.dcos/clusters/${CLUSTER_ID}/dcos.toml << EOM
[core]
dcos_url = "${DCOS_URL}"
ssl_verify = "false"
reporting = false
[cluster]
name = "DCOS"
EOM
  chmod 0600 ~/.dcos/clusters/${CLUSTER_ID}/dcos.toml
  # TODO: cluster name requires auth...
  # CLUSTER_NAME="$(curl --fail --location --silent --show-error ${DCOS_URL}/mesos/state-summary | jq -e -r .cluster)"
  # dcos cluster rename "DCOS" "${CLUSTER_NAME}"
else
  # < 1.10
  echo >&2 "Config: core.dcos_url=${DCOS_URL}"
  dcos config set core.dcos_url "${DCOS_URL}"
fi

# Log CLI & Cluster versions
dcos --version >&2

echo >&2 "Location:"
echo "${BIN}/${EXE}"
