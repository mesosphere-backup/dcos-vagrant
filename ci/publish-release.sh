#!/usr/bin/env bash

# Creates an pushes a new git tag.
#
# Usage:
# $ RELEASE_VERSION=1.1.1 ci/publish-release.sh

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${RELEASE_VERSION:-}" ]; then
  echo "RELEASE_VERSION must be set" >&2
  exit 1
fi

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

echo "Creating tag"
git tag -a v${RELEASE_VERSION} -m "Version ${RELEASE_VERSION}"
git push origin v${RELEASE_VERSION}
