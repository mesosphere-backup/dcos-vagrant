#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing DC/OS Postflight: /usr/sbin/dcos-postflight"

# from https://github.com/mesosphere/dcos-installer/blob/master/dcos_installer/action_lib/__init__.py#L250
# TODO: hopefully this goes away at some point so we dont have to write a looping postflight check

cat << 'EOF' > "/usr/sbin/dcos-postflight"
#!/usr/bin/env bash

# Polls dcos-download, dcos-setup, dcos-diagnostics, and dcos-adminrouter to determine node install progress.

set -o errexit -o nounset -o pipefail

# null globs required for finding cfg_files
shopt -s nullglob

TIMEOUT_SECONDS="900"
PROGRESS="time"

# Parse arguments
for i in "$@"; do
  case ${i} in
    -t=*|--timeout=*)
      TIMEOUT_SECONDS="${i#*=}"
      shift # past argument=value
      ;;
    -p=*|--progress=*)
      PROGRESS="${i#*=}"
      shift # past argument=value
      ;;
    *)
      echo >&2 "Invalid parameter: ${i}"
      exit 1
      ;;
  esac
done

# Validate TIMEOUT_SECONDS
if ! [[ "${TIMEOUT_SECONDS}" =~ ^[0-9][0-9]*$ ]]; then
  echo >&2 "Invalid timeout (not a number): ${key}"
  exit 1
fi

# Validate PROGRESS
case ${PROGRESS} in
  dots)
    PROGRESS_CMD="echo -n '.'"
    INLINE="-n"
    ;;
  time)
    PROGRESS_CMD="echo \"Polling \${TARGET} (\${TIMEOUT_SECONDS}s timeout)...\""
    INLINE=""
    ;;
  none)
    PROGRESS_CMD="true"
    INLINE=""
    ;;
  *)
    echo >&2 "Invalid progress (must be dots, time, or none): ${PROGRESS}"
    exit 1
    ;;
esac

# Run the DC/OS diagnostic script for up to the specified number of seconds to ensure
# we do not return ERROR on a cluster that hasn't fully achieved quorum.
function await() {
  case ${PROGRESS} in
    dots) echo -n "Polling ${TARGET} (${TIMEOUT_SECONDS}s timeout)" >&2;;
    none) echo "Polling ${TARGET} (${TIMEOUT_SECONDS}s timeout)..." >&2;;
  esac
  PREV_STATUS_OUT=""
  until eval "${PROGRESS_CMD}" >&2 && OUT=$(eval "${CMD}" 2>&1) || [[ TIMEOUT_SECONDS -eq 0 ]]; do
    if [[ -n "${STATUS_CMD}" ]]; then
      STATUS_OUT=$(eval "${STATUS_CMD}" 2>&1 || true)
      if [[ "${STATUS_OUT}" != "${PREV_STATUS_OUT}" ]]; then
        PREV_STATUS_OUT="${STATUS_OUT}"
        if [[ "${PROGRESS}" == "dots" ]]; then
          echo >&2 # newline
        fi
        echo "${STATUS_OUT}" >&2
      fi
    fi
    sleep 5
    let TIMEOUT_SECONDS=TIMEOUT_SECONDS-5
  done
  echo " SUCCESS" >&2 # newline
  RETCODE=$?
  if [[ "${RETCODE}" != "0" ]]; then
    echo "DC/OS Unhealthy\\n${OUT}" >&2
    exit ${RETCODE}
  fi
}

TARGET="dcos-download"
CMD="echo \"\$(systemctl status dcos-download || true)\" | grep 'Main PID:.*status=0/SUCCESS.*'"
STATUS_CMD=""
await

TARGET="dcos-setup"
CMD="echo \"\$(systemctl status dcos-setup || true)\" | grep 'Main PID:.*status=0/SUCCESS.*'"
STATUS_CMD=""
await

# Support multiple historical versions of dcos-diagnostics
if [[ -e "/opt/mesosphere/bin/dcos-diagnostics" ]]; then
  # DC/OS >= 1.10
  TARGET="dcos-diagnostics check node-poststart"
  CMD="/opt/mesosphere/bin/dcos-diagnostics check node-poststart"
  # parse the json output into something human readable, like:
  # components_master:
  #   component Admin Router Reloader has health status 1
  STATUS_CMD="echo \"\$(${CMD} 2>&1 || true)\" | jq -r '.checks | to_entries[] | select(.value.status != 0) | \"\(.key):\\n  \(.value.output | split(\"\\n\") | map(select(length > 0)) | join(\"\\n  \"))\"'"
elif [[ -e "/opt/mesosphere/bin/3dt" ]]; then
  # DC/OS <= 1.9
  TARGET="3dt --diag"
  CMD="/opt/mesosphere/bin/3dt --diag"
  # 3dt --diag will complain about missing endpoints_config.json if not
  # passed explicitly. This error is not influencing the diagnostics status.
  # This is a bug, which has been fixed in DC/OS >= 1.10
  cfg_files=( /opt/mesosphere/etc/dcos-3dt-endpoint-config*.json )
  cfg_files+=( /opt/mesosphere/endpoints_config*.json )
  cfg_files+=( /opt/mesosphere/etc/endpoints_config*.json )
  if [ ${#cfg_files[@]} -gt 0 ]; then
    CMD="${CMD} --endpoint-config=${cfg_files[0]}"
  fi
  STATUS_CMD=""
elif [[ -e "/opt/mesosphere/bin/dcos-diagnostics.py" ]]; then
  # DC/OS <= 1.6
  TARGET="dcos-diagnostics.py"
  CMD="/opt/mesosphere/bin/dcos-diagnostics.py"
  STATUS_CMD=""
else
  echo "Postflight Failure: dcos-diagnostics not found"
  exit 1
fi
await

# Different nodes types serve the API on different ports
if [[ -f /etc/mesosphere/roles/master ]]; then
  API_PORT=80 #TODO: 443 if in strict or permissive? (should redirect)
elif [[ -f /etc/mesosphere/roles/slave ]] || [[ -f /etc/mesosphere/roles/slave_public ]]; then
  API_PORT=61001 #TODO: 61002 if in strict or permissive? (should redirect)
else
  echo "Postflight Failure: unrecognized node type"
  exit 1
fi
TARGET="dcos-adminrouter"
if [[ -e "/opt/mesosphere/bin/dcos-diagnostics" ]]; then
    # DC/OS >= 1.10
    READINESS_CHECK_PATH=/dcos-metadata/dcos-version.json
else
    # DC/OS <= 1.9
    READINESS_CHECK_PATH=/
fi
CMD="curl --insecure --fail --location --silent http://127.0.0.1:${API_PORT}${READINESS_CHECK_PATH}"
STATUS_CMD="curl --insecure --fail --location --silent -o /dev/null -w "%{http_code}" http://127.0.0.1:${API_PORT}${READINESS_CHECK_PATH}"
await
EOF

chmod u+x "/usr/sbin/dcos-postflight"
