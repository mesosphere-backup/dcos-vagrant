#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! curl --fail --location --max-redir 0 --silent http://boot.dcos/dcos_install.sh; then
  >&2 echo "Warning: Bootstrap machine unreachable - postponing DC/OS public agent install - only an error if adding this node to an existing cluster"
  exit 0
fi

echo ">>> Installing DC/OS slave_public"
curl --fail --location --max-redir 0 --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public

echo ">>> Executing DC/OS Postflight"
dcos-postflight

if [ -n "${DCOS_TASK_MEMORY:-}" ]; then
  echo ">>> Setting Mesos Memory: ${DCOS_TASK_MEMORY} (role=slave_public)"
  mesos-memory ${DCOS_TASK_MEMORY} slave_public
  echo ">>> Restarting Mesos Agent"
  systemctl stop dcos-mesos-slave-public.service
  rm -f /var/lib/mesos/slave/meta/slaves/latest
  systemctl start dcos-mesos-slave-public.service --no-block
fi
