#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! probe tcp://boot.dcos:80; then
  >&2 echo "Bootstrap machine unreachable - postponing DC/OS slave install"
  exit 0
fi

echo ">>> Installing DC/OS slave"
curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave

echo ">>> Executing DC/OS Postflight"
dcos-postflight

if [ -n "${DCOS_TASK_MEMORY}" ]; then
  echo ">>> Setting Mesos Memory: ${DCOS_TASK_MEMORY} (role=*)"
  mesos-memory ${DCOS_TASK_MEMORY}
  echo ">>> Restarting Mesos Agent"
  systemctl stop dcos-mesos-slave.service
  rm -f /var/lib/mesos/slave/meta/slaves/latest
  systemctl start dcos-mesos-slave.service --no-block
fi
