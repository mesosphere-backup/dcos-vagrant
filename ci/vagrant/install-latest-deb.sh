#!/usr/bin/env bash

# Installs the latest Vagrant from deb file.
# For Debian or Debian-like operating systems, like Ubuntu.
# New binary will overwrite old binary (unless it changes between versions).
#
# Usage: install-latest.sh <x86_64|i686>

set -o errexit -o nounset -o pipefail

function create_temp_dir() {
  TMPDIR="${TMPDIR:-/tmp/}"
  echo "$(mktemp -d "${TMPDIR%/}/dcos-install-cli.XXXXXXXXXXXX")"
}

ARCH="${1:-}"
if [[ "${ARCH}" != 'x86_64' ]] && [[ "${ARCH}" != 'i686' ]]; then
  echo >&2 "Invalid architecture: must be 'x86_64' or 'i686' but found '${ARCH}'"
  echo >&2 "Usage: install-latest.sh <x86_64|i686>"
  exit 2
fi
echo >&2 "Architecture: ${ARCH}"

VAGRANT_VERSIONS_JSON="$(curl -s https://releases.hashicorp.com/vagrant/index.json)"
LATEST_VERSION="$(echo "${VAGRANT_VERSIONS_JSON}" | jq -e -r '.versions | keys | max')"
echo >&2 "Latest Version: ${LATEST_VERSION}"

DEB_URL=$(echo "${VAGRANT_VERSIONS_JSON}" | jq -e -r ".versions[\"${LATEST_VERSION}\"].builds[] | select(.arch==\"${ARCH}\") | select(.os==\"debian\") | .url")
echo >&2 "Deb URL: ${DEB_URL}"

DEB_FILE="$(basename "${DEB_URL}")"
echo >&2 "Deb File: ${DEB_FILE}"

DOWNLOAD_PATH="$(create_temp_dir)"
trap "rm -rf ${DOWNLOAD_PATH}" EXIT

echo >&2 "Downloading deb file..."
curl --fail --location --silent --show-error -o "${DOWNLOAD_PATH}/${DEB_FILE}" "${DEB_URL}"
echo >&2 "Downloaded deb file: ${DOWNLOAD_PATH}/${DEB_FILE}"

# detect if sudo is required
if [[ "${EUID}" != "0" ]]; then
  SUDO='sudo'
else
  SUDO=''
fi

echo >&2 "Installing from deb file..."
${SUDO} dpkg -i "${DOWNLOAD_PATH}/${DEB_FILE}"

echo >&2 "vagrant --version"
vagrant --version >&2

echo >&2 "which vagrant"
which vagrant
