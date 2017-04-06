#!/usr/bin/env bash

# Performs aggressive VM deletion.
# Vagrant destroy can be flaky. So this method tries harder.
#
# Usage:
# $ ci/cleanup.sh

vagrant destroy -f

for box in $( VBoxManage list vms | grep .dcos | cut -d '{' -f 2 | tr -d '}' ); do
  VBoxManage controlvm "$box" poweroff
  VBoxManage unregistervm "$box" --delete
done

vagrant global-status --prune
