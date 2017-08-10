#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing Mesos Memory Modifier: /usr/sbin/mesos-memory"

cat << 'EOF' > "/usr/sbin/mesos-memory"
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

MEMORY_MB="$1"
MEMORY_ROLE="${2:-*}"

# Always write to mesos-resources (may or may not already exist)
MESOS_RESOURCES_FILE=/var/lib/dcos/mesos-resources
mkdir -p "$(dirname "${MESOS_RESOURCES_FILE}")"

# Detect mesos agent systemd service
if systemctl is-active -q dcos-mesos-slave; then
  UNIT_NAME='dcos-mesos-slave'
elif systemctl is-active -q dcos-mesos-slave-public; then
  UNIT_NAME='dcos-mesos-slave-public'
else
  echo >&2 "ERROR: Neither dcos-mesos-slave or dcos-mesos-slave-public is active"
  exit 1
fi

# Use private agent config, if exists, otherwise public agent config.
UNIT_FILE="$(systemctl show -p FragmentPath ${UNIT_NAME} | cut -d'=' -f2)"
if [[ -z "${UNIT_FILE}" ]] || ! [[ -f "${UNIT_FILE}" ]]; then
  echo >&2 "ERROR: Can't find the systemd unit definition for ${UNIT_NAME}"
  exit 1
fi

# extract EnvironmentFiles from the systemd unit definition
ENV_FILES="$(grep "EnvironmentFile=" "${UNIT_FILE}" | cut -d'=' -f2)"
if [[ -z "${ENV_FILES}" ]]; then
  echo >&2 "ERROR: Can't find any EnvironmentFiles in the ${UNIT_NAME} systemd unit definition"
  echo >&2 "${UNIT_FILE}"
  echo >&2 "$(cat "${UNIT_FILE}")"
  exit 1
fi

# validate MESOS_RESOURCES_FILE is sourced by mesos agent
if ! (echo "${ENV_FILES}" | grep -q "^-\?${MESOS_RESOURCES_FILE}$"); then
  echo >&2 "ERROR: Can't find ${MESOS_RESOURCES_FILE} in EnvironmentFiles of ${UNIT_NAME}"
  echo >&2 "${ENV_FILES}"
  exit 1
fi

# systemd env files are not POSIX compliant, can't be sourced :(
# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=
function systemd_source() {
  local prev_line=""
  while read -r line; do
    # empty lines, lines without an "=" separator, or lines starting with ; or # will be ignored
    if [[ "${line}" == "" ]] || ! [[ "${line}" == *"="* ]] || [[ "${line}" == ";"* ]] || [[ "${line}" == "#"* ]]; then
      continue
    fi

    # A line ending with a backslash will be concatenated with the following one, allowing multiline variable definitions.
    if [[ -n "${prev_line}" ]]; then
      line="${prev_line}${line}"
    fi
    # TODO: allow spaces after backslash?
    if [[ "${line}" == *"\\" ]]; then
      # trim trailing backslash
      prev_line="${line::-1}"
      continue
    else
      # reset line buffer
      prev_line=""
    fi

    KEY="$(echo "${line}" | cut -d'=' -f1)"
    VALUE="$(echo "${line}" | cut -d'=' -f2)"

    # trim leading whitespace
    VALUE="${VALUE##*( )}"
    # trim trailing whitespace
    VALUE="${VALUE%%*( )}"

    # the parser strips leading and trailing whitespace from the values of assignments, unless you use double quotes (").
    if [[ "${VALUE}" == '"'*'"' ]]; then
      # trim wrapping double quotes
      VALUE="${VALUE:1:-1}"
      # assume any inner double quotes are already escaped
    elif [[ "${VALUE}" == "'"*"'" ]]; then
      # trim wrapping single quotes
      # apparently systemd supports this, even tho the doc doesn't mention it... :(
      VALUE="${VALUE:1:-1}"
      # escape double quotes
      VALUE="${VALUE//\"/\\\"}"
      # TODO: should whitespace be trimmed within single quotes? it's not documented...
    else
      # escape double quotes
      VALUE="${VALUE//\"/\\\"}"
    fi

    # eval and pray it's valid syntax
    eval "${KEY}=\"${VALUE}\""
  done <<< "$(cat "$1")"
}

# source all the same EnvironmentFiles in the same order
while read -r line; do
  if [[ "${line}" == "-"* ]]; then
    # optional file, strip first character
    line="${line:1}"
    if [[ -f "${line}" ]]; then
      systemd_source "${line}"
    fi
  else
    # required file
    systemd_source "${line}"
  fi
done <<< "${ENV_FILES}"

#echo "Value from ${UNIT_NAME} environment:"
#echo "MESOS_RESOURCES=$(echo "${MESOS_RESOURCES}" | jq -cM .)"

# ensure resource file exists and includes MESOS_RESOURCES so that it can be updated with sed
if [[ -f "${MESOS_RESOURCES_FILE}" ]]; then
  echo "Updating ${MESOS_RESOURCES_FILE}"
  if ! grep -q 'MESOS_RESOURCES=' "${MESOS_RESOURCES_FILE}"; then
    echo "MESOS_RESOURCES='[]'" >> "${MESOS_RESOURCES_FILE}"
  fi
else
  echo "Creating ${MESOS_RESOURCES_FILE}"
  echo "MESOS_RESOURCES='[]'" > "${MESOS_RESOURCES_FILE}"
fi

if echo "${MESOS_RESOURCES}" |  jq -e '.[] | select(.name=="mem")' > /dev/null; then
  # update memory value
  MESOS_RESOURCES="$(echo "${MESOS_RESOURCES}" |  jq "map(select(.name==\"mem\").scalar.value=${MEMORY_MB})" -cMj)"
else
  # append memory hash
  MESOS_RESOURCE_MEMORY='{"name": "mem", "role":"*", "type": "SCALAR", "scalar": {"value": 1024}}'
  MESOS_RESOURCE_MEMORY="$(echo "${MESOS_RESOURCE_MEMORY}" | jq ".scalar.value = ${MEMORY_MB}" -cMj)"
  MESOS_RESOURCE_MEMORY="$(echo "${MESOS_RESOURCE_MEMORY}" | jq ".role = \"${MEMORY_ROLE}\"" -cMj)"
  MESOS_RESOURCES="$(echo "${MESOS_RESOURCES} [${MESOS_RESOURCE_MEMORY}]" | jq -scMj add)"
fi

#echo "New Value:"
#echo "MESOS_RESOURCES=${MESOS_RESOURCES}"

# three-stage update for cross-platform support and better failure behavior
cp "${MESOS_RESOURCES_FILE}" "${MESOS_RESOURCES_FILE}.bak"
sed "s/MESOS_RESOURCES=.*/MESOS_RESOURCES='${MESOS_RESOURCES}'/" "${MESOS_RESOURCES_FILE}.bak" > "${MESOS_RESOURCES_FILE}"
rm "${MESOS_RESOURCES_FILE}.bak"
EOF

chmod u+x "/usr/sbin/mesos-memory"
