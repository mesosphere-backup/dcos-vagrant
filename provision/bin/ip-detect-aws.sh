#!/bin/sh
set -o nounset -o errexit

mkdir -p ~/dcos/genconf

cat << EOF > ~/dcos/genconf/ip-detect
#!/bin/sh
set -o nounset -o errexit

curl -fsSL http://169.254.169.254/latest/meta-data/local-ipv4

EOF
