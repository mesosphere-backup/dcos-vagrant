#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ "$(docker inspect -f '{{.State.Running}}' zookeeper-boot 2>/dev/null)" != "true" ]; then
  echo ">>> Starting zookeeper (for exhibitor bootstrap and quorum)"
  docker run -d --name=zookeeper-boot -p 2181:2181 -p 2888:2888 -p 3888:3888 --restart=always jplock/zookeeper
else
  echo ">>> Found zookeeper container running"
fi

if [ "$(docker inspect -f '{{.State.Running}}' nginx-boot 2>/dev/null)" != "true" ]; then
  echo ">>> Starting nginx (for distributing bootstrap artifacts to cluster)"
  docker run -d --name=nginx-boot -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 --restart=always nginx
else
  echo ">>> Found nginx container running"
fi

# Provide a local docker registry for testing purposes. Agents will also get
# the boot node allowed as an insecure registry.
if [ "${DCOS_PRIVATE_REGISTRY}" == "true" ]; then
  if [ "$(docker inspect -f '{{.State.Running}}' registry-boot)" != "true" ]; then
    echo ">>> Starting private docker registry"
    docker run -d --name=registry-boot -p 5000:5000 --restart=always registry:2
  else
    echo ">>> Found registry container running"
  fi
fi

if [ "${DCOS_JAVA_ENABLED:-false}" == "true" ]; then
  echo ">>> Copying java artifacts to nginx directory (/var/tmp/dcos/java)."
  mkdir -p /var/tmp/dcos/java
  cp -rp /vagrant/provision/gs-spring-boot-0.1.0.jar /var/tmp/dcos/java/
  cp -rp /vagrant/provision/jre-*-linux-x64.* /var/tmp/dcos/java/
fi

mkdir -p ~/dcos/genconf

echo ">>> Downloading dcos_generate_config.sh (for building bootstrap image for system)"
curl --fail --silent --show-error "${DCOS_GENERATE_CONFIG_PATH}" > ~/dcos/dcos_generate_config.sh
