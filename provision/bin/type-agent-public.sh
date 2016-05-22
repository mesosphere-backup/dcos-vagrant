#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! probe tcp://boot.dcos:80; then
  >&2 echo "Bootstrap machine unreachable - postponing DC/OS slave install"
  exit 0
fi

echo ">>> Installing DC/OS slave_public"
curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public

echo ">>> Executing DC/OS Postflight"
dcos-postflight

if [ -n "${DCOS_TASK_MEMORY}" ]; then
  echo ">>> Setting Mesos Memory: ${DCOS_TASK_MEMORY} (role=slave_public)"
  mesos-memory ${DCOS_TASK_MEMORY} slave_public
  echo ">>> Restarting Mesos Agent"
  systemctl stop dcos-mesos-slave-public.service
  rm -f /var/lib/mesos/slave/meta/slaves/latest
  systemctl start dcos-mesos-slave-public.service --no-block
fi
