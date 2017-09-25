#!/usr/bin/env bash

# Polls a URL until it is healthy (200) using curl.
# Times out after 5 minutes.
#
# Usage:
# $ ci/await-url-health.sh <url> [timeout-seconds]

set -o errexit -o nounset -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

URL="${1}"
MAX_ELAPSED="${2:-300}" # In seconds. Default: 5 minutes.

SUCCESS=false
START_TIME=${SECONDS}
while [[ $((${SECONDS} - ${START_TIME})) -lt ${MAX_ELAPSED} ]]; do
  echo "Polling url (${URL}) health..."
  if OUTPUT="$(curl --fail --location --silent --show-error "${URL}/" -o /dev/null)"; then
    SUCCESS=true
    break
  fi
  sleep 5
done
if [[ "${SUCCESS}" == true ]]; then
  echo >&2 "URL (${URL}) healthy"
else
  echo >&2 "URL (${URL}) unhealthy -- Timed out after ${MAX_ELAPSED} seconds."
  echo >&2 "${OUTPUT:-}"
  exit 1
fi
