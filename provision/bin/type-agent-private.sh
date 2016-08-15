#!/usr/bin/env bash

set -o nounset
set -o pipefail

# By default, agents are provisioned in parallel during boot machine provisioning.
# The following agent provisioning should only run if the boot machine provisioning has already occurred.
# This ready check validates that the boot machine is ready and not just being impersonated by DNS hijacking.
if [ "$(curl --fail --location --max-redir 0 --silent http://boot.dcos/ready)" != "ok" ]; then
  echo "Skipping DC/OS private agent install (boot machine will provision in parallel)"
  exit 0
fi

set -o errexit

echo ">>> Installing DC/OS slave"
curl --fail --location --max-redir 0 --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave

echo ">>> Executing DC/OS Postflight"
dcos-postflight

if [ -n "${DCOS_TASK_MEMORY:-}" ]; then
  echo ">>> Setting Mesos Memory: ${DCOS_TASK_MEMORY} (role=*)"
  mesos-memory ${DCOS_TASK_MEMORY}
  echo ">>> Restarting Mesos Agent"
  systemctl stop dcos-mesos-slave.service
  rm -f /var/lib/mesos/slave/meta/slaves/latest
  systemctl start dcos-mesos-slave.service --no-block
fi
