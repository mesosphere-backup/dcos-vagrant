#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

APP_ID="${1}"

echo >&2  "Looking up app (${APP_ID}) instances..."
INSTANCES="$(dcos marathon app show "${APP_ID}" | jq '.instances')"
echo >&2  "Found app (${APP_ID}) instances: ${INSTANCES}"

SUCCESS=false
START_TIME=${SECONDS}
MAX_ELAPSED=300 #5min
while [[ $((${SECONDS} - ${START_TIME})) -lt ${MAX_ELAPSED} ]]; do
  echo "Polling app (${APP_ID}) instance health..."
  if [[ "$(dcos marathon app show "${APP_ID}" | jq '.tasksHealthy')" == "${INSTANCES}" ]]; then
    SUCCESS=true
    break
  fi
  sleep 5
done
if [[ "${SUCCESS}" = true ]]; then
  echo >&2 "App (${APP_ID}) healthy"
else
  echo >&2 "App (${APP_ID}) unhealthy -- Timed out after 5 minutes."
  exit 1
fi
