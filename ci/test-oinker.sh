#!/usr/bin/env bash

# Installs and tests Oinker on DC/OS Vagrant.
# Requires dcos CLI to be installed, configured, and logged in.
#
# Usage:
# $ ci/test-oinker.sh

set -o errexit -o nounset -o pipefail -o xtrace

OINKER_HOST="${OINKER_HOST:-oinker.acme.org}"

project_dir=$(cd "$(dirname "${BASH_SOURCE}")/.." && pwd -P)
cd "${project_dir}"

source vendor/semver_bash/semver.sh

# CLI v0.5.3 added a confirmation prompt to uninstall and --yes to bypass it.
CLI_VERSION="$(dcos --version | grep dcoscli.version | cut -d'=' -f2)"
if semverLT "${CLI_VERSION}" "0.5.3"; then
  CONFIRM=''
else
  CONFIRM='--yes'
fi

# Print config for debugging purposes
dcos config show

# Install Cassandra
# Stick to v1.x because it allows 1-node Cassandra, while v2.x does not.
dcos package install --options=examples/oinker/pkg-cassandra.json cassandra --package-version=1.0.25-3.0.10 --yes
ci/await-app-health.sh 'cassandra'

# Install Marathon-LB
dcos package install --options=examples/oinker/pkg-marathon-lb.json marathon-lb --yes
ci/await-app-health.sh 'marathon-lb'

# Install Oinker
dcos marathon app add examples/oinker/oinker.json
ci/await-app-health.sh 'oinker'

# Block until Marathon-LB routing works (1 minute timeout)
ci/await-url-health.sh "http://${OINKER_HOST}/" 60

# Test load balancing uses all instances
ci/test-oinker-lb.sh

# Test posting and reading posts
ci/test-oinker-oinking.sh

# Uninstall Oinker
dcos marathon app remove oinker

# Uninstall Marathon-LB
dcos package uninstall marathon-lb ${CONFIRM}

# Uninstall Cassandra
dcos package uninstall cassandra ${CONFIRM}

# Clean up Mesos & ZooKeeper
# DC/OS 1.10 added auto-cleanup, but Cassandra 1.x doesn't use it.
dcos node ssh --leader --user=vagrant --option StrictHostKeyChecking=no --option IdentityFile=$(pwd)/.vagrant/dcos/private_key_vagrant \
     "docker run mesosphere/janitor /janitor.py -r cassandra-role -p cassandra-principal -z dcos-service-cassandra"
