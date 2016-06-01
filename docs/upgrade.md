# Upgrade

In-place upgrading of DC/OS is not currently supported using DC/OS Vagrant. Existing clusters must be [destroyed](/docs/deploy.md#destroy) before a new one can be created.

For version compatibility, see [Supported DC/OS Versions](/docs/deploy.md#supported-dcos-versions).

**Upgrade to a new version of DC/OS Vagrant**:

1. Change into the repo directory (e.g. `cd ~/workspace/dcos-vagrant`)
1. Fetch the new code (e.g. `git fetch`)
1. Check out the new desired version (e.g. `git checkout v0.7.0` or `git checkout master`)

**Upgrade to a new version of DC/OS**:

1. Download a new release from [DC/OS Releases](https://dcos.io/releases/)
2. Move the new `dcos_generate_config.sh` into the dcos-vagrant repo directory
3. Update the DC/OS config (e.g. `export DCOS_CONFIG_PATH=etc/config-1.7.yaml`)
