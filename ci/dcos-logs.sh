#!/usr/bin/env bash

# Extracts the journalctl logs on each node.
# Writes to <container-name>.log
#
# Flags:
#  -n --lines=INTEGER    Number of journal entries to show
#
# Usage:
# $ ci/dcos-logs.sh [--lines=N]

set -o errexit -o nounset -o pipefail

for i in "$@"; do
  case ${i} in
    -n=*|--lines=*)
      LINES="${i#*=}"
      LINES_ARG="-n ${LINES}"
      shift # past argument=value
      ;;
    *)
      echo >&2 "Invalid parameter: ${i}"
      exit 1
      ;;
  esac
done

while read -r VM_NAME; do
  echo "Extracting Logs: ${VM_NAME}"
  VAGRANT_LOG=error < /dev/null vagrant ssh "${VM_NAME}" -c "journalctl --no-pager ${LINES_ARG:-}" > "${VM_NAME}.log"
done < <(grep '.dcos' /etc/hosts | sed 's/^.*[[:space:]][[:space:]]*\(.*\)\.dcos.*$/\1/')
