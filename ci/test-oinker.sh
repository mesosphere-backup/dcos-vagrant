#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)

cd "${project_dir}"

# Install Cassandra
dcos package install --options=examples/oinker/pkg-cassandra.json cassandra --yes
ci/test-app-health.sh 'cassandra'

# Install Marathon-LB
dcos package install --options=examples/oinker/pkg-marathon-lb.json marathon-lb --yes
ci/test-app-health.sh 'marathon-lb'

# Install Oinker
dcos marathon app add examples/oinker/oinker.json
ci/test-app-health.sh 'oinker'

# Test HTTP status
curl --fail --location --silent --show-error http://oinker.acme.org/ -o /dev/null

# Test load balancing uses all instances
ci/test-oinker-lb.sh

# Test posting and reading posts
ci/test-oinker-oinking.sh
