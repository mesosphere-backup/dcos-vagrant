#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

function create_temp_dir() {
  TMPDIR="${TMPDIR:-/tmp/}"
  echo "$(mktemp -d "${TMPDIR%/}/dcos-install-cli.XXXXXXXXXXXX")"
}

ARCH="${1:-}"
if [[ "${ARCH}" != 'x86_64' ]] && [[ "${ARCH}" != 'i686' ]]; then
  echo >&2 "Invalid architecture: must be 'x86_64' or 'i686' but found '${ARCH}'"
  echo >&2 "Usage: install-latest.sh <x86_64|i686>"
fi
echo >&2 "Architecture: ${ARCH}"

VAGRANT_VERSIONS_JSON="$(curl -s https://releases.hashicorp.com/vagrant/index.json)"
LATEST_VERSION="$(echo "${VAGRANT_VERSIONS_JSON}" |jq -r '.versions | keys' | jq -r max)"
echo >&2 "Latest Version: ${LATEST_VERSION}"

DEB_URL=$(echo ${VAGRANT_VERSIONS_JSON}" | jq -r ".versions" | jq -r ".[\"${LATEST_VERSION}\"]" | jq -r ".builds | .[] | select(.arch==\"${ARCH}\") | select(.os==\"debian\") | .url")
echo >&2 "Deb URL: ${DEB_URL}"

DEB_FILE="$(basename "${DEB_URL}")"
echo >&2 "Deb File: ${DEB_FILE}"

DOWNLOAD_PATH="$(create_temp_dir)"
trap "rm -rf ${DOWNLOAD_PATH}" EXIT

echo >&2 "Downloading deb file..."
curl --fail --location --silent --show-error -o "${DOWNLOAD_PATH}/${DEB_FILE}" "${DEB_URL}"
echo >&2 "Downloaded deb file: ${DOWNLOAD_PATH}/${DEB_FILE}"

echo >&2 "Installing from deb file..."
sudo dpkg -i "${DOWNLOAD_PATH}/${DEB_FILE}"

echo >&2 "vagrant --version"
vagrant --version >&2

echo >&2 "which vagrant"
which vagrant
