#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing DC/OS Postflight: /usr/local/sbin/dcos-postflight"

# from https://github.com/mesosphere/dcos-installer/blob/master/dcos_installer/action_lib/__init__.py#L250
# TODO: hopefully this goes away at some point so we dont have to write a looping postflight check

cat << 'EOF' > "/usr/local/sbin/dcos-postflight"
#!/usr/bin/env bash
shopt -s nullglob

# Run the DC/OS diagnostic script for up to the specified number of seconds to ensure
# we do not return ERROR on a cluster that hasn't fully achieved quorum.
TIMEOUT_SECONDS="${1:-900}"
if [[ -e "/opt/mesosphere/bin/dcos-diagnostics" ]]; then
    # DC/OS >= 1.10
    CMD="/opt/mesosphere/bin/dcos-diagnostics --diag"
elif [[ -e "/opt/mesosphere/bin/3dt" ]]; then
    # DC/OS <= 1.9
    # 3dt --diag will complain about missing endpoints_config.json if not
    # passed explicitly. This error is not influencing the diagnostics status.
    # This is a bug, which has been fixed in DC/OS >= 1.10
    CMD="/opt/mesosphere/bin/3dt --diag"
    cfg_files=( /opt/mesosphere/etc/dcos-3dt-endpoint-config*.json )
    cfg_files+=( /opt/mesosphere/endpoints_config*.json )
    cfg_files+=( /opt/mesosphere/etc/endpoints_config*.json )
    if [ ${#cfg_files[@]} -gt 0 ]; then
        CMD="${CMD} --endpoint-config=${cfg_files[0]}"
    fi
elif [[ -e "/opt/mesosphere/bin/dcos-diagnostics.py" ]]; then
    # DC/OS <= 1.6
    CMD="/opt/mesosphere/bin/dcos-diagnostics.py"
else
    echo "Postflight Failure: either 3dt or dcos-diagnostics.py must be present"
    exit 1
fi
until OUT=$(${CMD} 2>&1) || [[ TIMEOUT_SECONDS -eq 0 ]]; do
    sleep 5
    let TIMEOUT_SECONDS=TIMEOUT_SECONDS-5
done
RETCODE=$?
if [[ "${RETCODE}" != "0" ]]; then
    echo "DC/OS Unhealthy\n${OUT}" >&2
fi
exit ${RETCODE}
EOF

chmod u+x "/usr/local/sbin/dcos-postflight"
