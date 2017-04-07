#!/usr/bin/env bash

# Performs aggressive VM deletion.
# Vagrant destroy can be flaky. So this method tries harder.
#
# Usage:
# $ ci/cleanup.sh

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

VBM="$(ci/find-vboxmanage.sh)"

vagrant destroy -f

for box in $( "${VBM}" list vms | grep .dcos | cut -d '{' -f 2 | tr -d '}' ); do
  "${VBM}" controlvm "$box" poweroff
  "${VBM}" unregistervm "$box" --delete
done

vagrant global-status --prune
