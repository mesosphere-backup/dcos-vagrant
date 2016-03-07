#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Starting zookeeper (for exhibitor bootstrap and quorum)"
docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 --restart=always jplock/zookeeper

echo ">>> Starting nginx (for distributing bootstrap artifacts to cluster)"
docker run -d -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 --restart=always nginx

# Provide a local docker registry for testing purposes. Agents will also get
# the boot node allowed as an insecure registry.
if [ "${DCOS_PRIVATE_REGISTRY}" == "true" ]; then
  echo ">>> Starting private docker registry"
  docker run -d -p 5000:5000 --restart=always registry:2
fi

if [ "${DCOS_JAVA_ENABLED:-false}" == "true" ]; then
  echo ">>> Copying java artifacts to nginx directory (/var/tmp/dcos/java)."
  mkdir -p /var/tmp/dcos/java
  cp -rp /vagrant/provision/gs-spring-boot-0.1.0.jar /var/tmp/dcos/java/
  cp -rp /vagrant/provision/jre-*-linux-x64.* /var/tmp/dcos/java/
fi

mkdir -p ~/dcos/genconf

echo ">>> Downloading dcos_generate_config.sh (for building bootstrap image for system)"
curl "${DCOS_GENERATE_CONFIG_PATH}" > ~/dcos/dcos_generate_config.sh
