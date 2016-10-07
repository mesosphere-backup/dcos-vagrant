#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo ">>> Installing Certificate Authorities"
# DC/OS was compiled on ubuntu with certs in a different place!
if [ "$(readlink /etc/ssl/certs/ca-certificates.crt)" != "/etc/ssl/certs/ca-bundle.crt" ]; then
  ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
fi
