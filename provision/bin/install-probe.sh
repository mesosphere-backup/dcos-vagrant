#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

LOCATION="/usr/sbin/probe"

if hash probe 2>/dev/null; then
  echo "Probe already installed: $(which probe)"
  if [[ "$(which probe)" != "${LOCATION}" ]]; then
    echo "Moving probe: ${LOCATION}"
    mv "$(which probe)" "${LOCATION}"
  fi
  exit 0
fi

echo ">>> Installing Probe: ${LOCATION}"

WORK_DIR="$(mktemp -d)"
trap "rm -rf '${WORK_DIR}'" EXIT

cd "${WORK_DIR}"

PROBE_VERSION=0.3.0
PROBE_CHECKSUMS_PATH="probe-${PROBE_VERSION}-checksums"
PROBE_ARCHIVE_PATH="probe-${PROBE_VERSION}-linux_amd64.tgz"
PROBE_ARCHIVE_URL="https://github.com/karlkfi/probe/releases/download/v${PROBE_VERSION}/probe-${PROBE_VERSION}-linux_amd64.tgz"

curl --fail --location --silent --show-error --output "${PROBE_ARCHIVE_PATH}" "${PROBE_ARCHIVE_URL}"

tee "${PROBE_CHECKSUMS_PATH}" <<-EOF
5e12339fa770b58ca7b7c4291927390d0ad9f61e6cf95e2572c5de5a7a8db0ec *${PROBE_ARCHIVE_PATH}
EOF

if ! sha256sum -c "${PROBE_CHECKSUMS_PATH}" --status; then
  >&2 echo "Invalid archive checksum"
  exit 1
fi

tar -zxf "${PROBE_ARCHIVE_PATH}" --directory "${WORK_DIR}/"

mv "${WORK_DIR}/probe" "${LOCATION}"
