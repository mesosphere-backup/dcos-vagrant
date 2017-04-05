#!/usr/bin/env bash

# VirtualBox shutdown/delete is a bit flaky. So perform some more aggressive destruction.

vagrant destroy -f

for box in $( VBoxManage list vms | grep .dcos | cut -d '{' -f 2 | tr -d '}' ); do
  VBoxManage controlvm "$box" poweroff
  VBoxManage unregistervm "$box" --delete
done

vagrant global-status --prune
