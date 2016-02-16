#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# DCOS' libcurl expects Ubuntu's 'ca-certificates.crt', but CentOS names it 'ca-bundle.crt'.
# Bridge this gap with a symlink.
AVAILABLE_CERT_PATH=/etc/ssl/certs/ca-bundle.crt
REQUIRED_CERT_PATH=/etc/ssl/certs/ca-certificates.crt
if [ -f ${REQUIRED_CERT_PATH} ]; then
    echo ">>> Skipping SSL cert symlink"
else
    echo ">>> Creating SSL cert symlink"
    if [ ! -f ${AVAILABLE_CERT_PATH} ]; then
        echo "!!! Missing expected certificate file at ${REQUIRED_CERT_PATH}. Exiting!"
        exit 1
    fi
    ln -s ${AVAILABLE_CERT_PATH} ${REQUIRED_CERT_PATH}
fi
