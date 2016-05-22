#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if hash jq 2>/dev/null; then
  echo "jq already installed: $(which jq)"
  exit 0
fi

echo ">>> Installing jq: /usr/local/sbin/jq"

WORK_DIR="$(mktemp -d)"
trap "rm -rf '${WORK_DIR}'" EXIT

cd "${WORK_DIR}"

JQ_BINARY_URL="https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"

curl --fail --location --silent --show-error --output "jq-linux64" "${JQ_BINARY_URL}"

tee "jq-checksums" <<-EOF
c6b3a7d7d3e7b70c6f51b706a3b90bd01833846c54d32ca32f0027f00226ff6d *jq-linux64
EOF

if ! sha256sum -c "jq-checksums" --status; then
  >&2 echo "Invalid executable checksum"
  exit 1
fi

mv "jq-linux64" "/usr/local/sbin/jq"
chmod a+x "/usr/local/sbin/jq"
