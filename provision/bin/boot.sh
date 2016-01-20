#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Creating docker service (jplock/zookeeper) for exhibitor bootstrap and quorum."
docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 jplock/zookeeper

echo ">>> Creating docker service (nginx) for ease of distributing bootstrap artifacts to cluster."
docker run -d -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 nginx
docker ps

DCOS_CONFIG_EXT="${DCOS_CONFIG##*.}"
echo ">>> Copying (ip-detect, config.${DCOS_CONFIG_EXT}) for building bootstrap image for system."
mkdir -p ~/dcos/genconf
cp "/vagrant/etc/${IP_DETECT_SCRIPT}" ~/dcos/genconf/ip-detect
# support json or yaml config files
cp "/vagrant/etc/${DCOS_CONFIG}" "${HOME}/dcos/genconf/config.${DCOS_CONFIG_EXT}"

echo ">>> Downloading (dcos_generate_config.sh) for building bootstrap image for system."
curl "${DCOS_GENERATE_CONFIG_PATH}" > ~/dcos/dcos_generate_config.sh

cd ~/dcos
echo ">>> Building bootstrap artifacts under ($(pwd)/genconf/serve)."
bash ./dcos_generate_config.sh --genconf

sleep 5

echo ">>> Copying bootstrap artifacts to nginx directory (/var/tmp/dcos)."
cp -rpv ~/dcos/genconf/serve/* /var/tmp/dcos/

if [ "${JAVA_ENABLED:-false}" == "true" ]; then
  echo ">>> Copying java artifacts to nginx dir (/var/tmp/dcos/java)."
  mkdir -p /var/tmp/dcos/java
  cp -rp /vagrant/build/gs-spring-boot-0.1.0.jar /var/tmp/dcos/java/
  cp -rp /vagrant/build/jre-*-linux-x64.* /var/tmp/dcos/java/
fi
