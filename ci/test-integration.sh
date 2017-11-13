#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

#TODO: detect agent IPs
export SLAVE_HOSTS=192.168.65.111,192.168.65.121
export PUBLIC_SLAVE_HOSTS=192.168.65.60
export VAGRANT_LOG=error

vagrant ssh m1 -c " \
  set -o errexit -o nounset -o pipefail && \
  source /opt/mesosphere/environment.export && \
  source /opt/mesosphere/active/dcos-integration-test/util/test_env.export || \
    source /opt/mesosphere/active/dcos-integration-test/test_env.export || \
      true && \
  export SLAVE_HOSTS='${SLAVE_HOSTS}' && \
  export PUBLIC_SLAVE_HOSTS='${PUBLIC_SLAVE_HOSTS}' && \
  cd /opt/mesosphere/active/dcos-integration-test && \
  pytest -vv --junitxml=/vagrant/test-junit.xml -m 'not ccm' \
"
