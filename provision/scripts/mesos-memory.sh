#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

MEMORY_MB="$1"
MEMORY_ROLE="${2:-*}"

mkdir -p /var/lib/dcos

if [ -f /var/lib/dcos/mesos-resources ]; then
  MESOS_RESOURCES_FILE=/var/lib/dcos/mesos-resources
else
  MESOS_RESOURCES_FILE=/var/lib/dcos/mesos-slave-common
  if !([ -f /var/lib/dcos/mesos-slave-common ] && cat /var/lib/dcos/mesos-slave-common | grep -q 'MESOS_RESOURCES='); then
    echo "MESOS_RESOURCES='[]'" >> /var/lib/dcos/mesos-slave-common
  fi
fi

source "${MESOS_RESOURCES_FILE}"

if echo "${MESOS_RESOURCES}" |  jq -e '.[] | select(.name=="mem")' > /dev/null; then
  # update memory value
  MESOS_RESOURCES_NEW="$(echo "${MESOS_RESOURCES}" |  jq "map(select(.name==\"mem\").scalar.value=${MEMORY_MB})" -cMj)"
else
  # append memory hash
  MESOS_RESOURCE_MEMORY='{"role":"*", "type": "SCALAR", "name": "mem", "scalar": {"value": 1024}}'
  MESOS_RESOURCE_MEMORY="$(echo "${MESOS_RESOURCE_MEMORY}" | jq ".scalar.value = ${MEMORY_MB}" -cMj)"
  MESOS_RESOURCE_MEMORY="$(echo "${MESOS_RESOURCE_MEMORY}" | jq ".role = \"${MEMORY_ROLE}\"" -cMj)"
  MESOS_RESOURCES_NEW="$(echo "${MESOS_RESOURCES} [${MESOS_RESOURCE_MEMORY}]" | jq -scMj add)"
fi

if [ "${MESOS_RESOURCES}" == "${MESOS_RESOURCES_NEW}" ]; then
  exit 0
fi

sed -i "s/MESOS_RESOURCES=.*/MESOS_RESOURCES='${MESOS_RESOURCES_NEW}'/" "${MESOS_RESOURCES_FILE}"
echo "Updated: ${MESOS_RESOURCES_FILE}"
