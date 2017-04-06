#!/usr/bin/env bash

# Tests Oinker's usage of Marathon-LB.
# Requires dcos CLI to be installed, configured, and logged in.
# Requires Oinker to be installed, running, and healthy.
#
# Options:
#   APP_ID (default: oinker)
#
# Usage:
# $ ci/test-oinker-lb.sh

set -o errexit
set -o nounset
set -o pipefail

APP_ID="${APP_ID:-oinker}"

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

# Require bash 4+ for associative arrays
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
  echo "Requires Bash 4+" >&2
  exit 1
fi

echo >&2  "Looking up app (${APP_ID}) instances..."
INSTANCES="$(dcos marathon app show "${APP_ID}" | jq '.instances')"

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
