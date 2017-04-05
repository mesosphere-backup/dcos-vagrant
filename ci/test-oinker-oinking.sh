#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

NUM_OINKS=20

echo >&2 "Posting ${NUM_OINKS} Oinks..."
for i in $(seq 1 ${NUM_OINKS}); do
  HANDLE="test-user-${i}"
  CONTENT="test-oink-${i}"

  echo "[Oink] ${HANDLE}: ${CONTENT}"
  HTML="$(curl --fail --silent --show-error -X POST -d "handle=${HANDLE}&content=${CONTENT}" http://oinker.acme.org/oink)"

  # find the handle & content in the response html
  if ! echo "${HTML}" | grep -q "@${HANDLE} " && echo "${HTML}" | grep -q "${CONTENT}"; then
    echo >&2 "ERROR: Failed to find oink in response HTML!"
    exit 1
  fi
done
echo >&2 "Oinking works!"
