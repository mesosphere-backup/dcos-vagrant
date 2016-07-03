#!/usr/bin/env bash
# Run the DC/OS diagnostic script for up to the specified number of seconds to ensure
# we do not return ERROR on a cluster that hasn't fully achieved quorum.

TIMEOUT_SECONDS="${1:-900}"
if [[ -e "/opt/mesosphere/bin/3dt" ]]; then
    # DC/OS >= 1.7
    CMD="/opt/mesosphere/bin/3dt -diag"
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
