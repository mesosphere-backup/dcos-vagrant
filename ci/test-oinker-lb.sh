#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

INSTANCES=3

# Test load balancing uses all instances
echo "Polling oinker.acme.org for Task ID..."
declare -A TASK_IDS=()
START_TIME=${SECONDS}
while [[ ${#TASK_IDS[@]} -lt ${INSTANCES} ]]; do
  TASK_ID="$(curl --fail --location --silent --show-error http://oinker.acme.org/ | grep '<div.*>oinker.*</div>' | sed 's/.*\(oinker\.[^<]*\).*/\1/')"

  # strip arithmetic operators not allowed in associative array keys
  TASK_ID="${TASK_ID//.}"
  TASK_ID="${TASK_ID//-}"

  TASK_IDS[$TASK_ID]=true

  ELAPSED_TIME=$((${SECONDS} - ${START_TIME}))
  if [[ ${ELAPSED_TIME} -gt 30 ]]; then
    echo >&2 "Load balancing failure -- Timed out after 30 seconds."
    exit 1
  fi
done
echo >&2 "Tasks seen:" "${#TASK_IDS[@]}"
