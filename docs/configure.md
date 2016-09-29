# Configure DC/OS Vagrant

The number of machines and their resources is configurable, depending on your needs and hardware constraints.

The [VagrantConfig.yaml.example](/VagrantConfig.yaml.example) includes some preset machine configurations that have been chosen to allow the widest possible use cases within a constrained memory environment (e.g. a laptop with 16GB memory). These presets may or may not fit your use case. If they don't, just modify your `VagrantConfig.yaml` file to fit your needs.

Deploying multiple VMs takes a lot of memory and Mesos reserves more for overhead on each node. So don't expect to be able to install every DC/OS service or use production-grade configurations. Most services will require reduced configurations in order to fit within the allocated memory. Some services (e.g. Cassandra) may require more nodes/resources than others.

For more information about how the DC/OS installation works and how to debug deployment/installation failure, see [DC/OS Install Process](/docs/dcos-install-process.md).

## Node Types

Each machine in `VagrantConfig.yaml` must specify one of the following node types that governs how that machine will be provisioned:

- `master` - Master node that runs the DC/OS core components (e.g. `m1`)
- `agent-private` - Agent node that runs the Mesos agent with the `*` role (e.g. `a1`)
- `agent-public` - Agent node that runs the Mesos agent with the `slave_public` role (e.g. `p1`)
- `boot` - Bootstrap node that runs the installer (e.g. `boot`)

## Cluster Constraints

Which exact machines are created and provisioned can be specified in one of two ways:

1. Specify the machines by name when deploying (e.g. `vagrant up m1 a1 p1 boot`)
1. Remove the unwanted machines from the `VagrantConfig.yaml` file and deploy them all with `vagrant up`

Generally option 1 is recommended to avoid having to modify the `VagrantConfig.yaml` file.

When selecting which machines to deploy, the following constraints must be observed:

- An odd number of master nodes is required (usually 1, 3, or 5)
- Any number of public and/or private agent nodes is allowed
- Exactly one bootstrap node is required
- The bootstrap node must be provisioned last

## Resource Constraints

DC/OS services will be installed on Mesos agent nodes. Mesos will auto-detect the amount of resources available on these machines, with the following constraint:

- Mesos reserves half or 1 GB of each machine's memory for overhead (whichever is least)

For example, `m1` has 3328 MB memory by default. Some of that memory will be taken by OS and DC/OS component processes (~ MB). 1 GB will be reserved by Mesos as overhead. The rest will be offered to Mesos frameworks for launching tasks (~ MB).

**IMPORTANT**: Make sure your local machine has enough memory to launch all your desired VMs, otherwise your machine may lock up as all the memory is consumed.


## Environment Options

There are several configurable options when deploying a cluster and installing DC/OS on it. Most of them are configurable via environment variables:

- `DCOS_BOX` - VirtualBox box image name (default: `mesosphere/dcos-centos-virtualbox`)
- `DCOS_BOX_URL` - VirtualBox box image url or vagrant-cloud style image repo (default: `https://downloads.dcos.io/dcos-vagrant/metadata.json`)
- `DCOS_BOX_VERSION` - VirtualBox box image version (default: `~> 0.5.0`)
- `DCOS_MACHINE_CONFIG_PATH` - Path to virtual machine configuration manifest (default: `VagrantConfig.yaml`)
    - Must contain at least one `boot` type machine, one `master` type machine, and one `agent` or `agent-public` type machine.
- `DCOS_CONFIG_PATH` - Path to DC/OS configuration template (default: `etc/config.yaml`)
    - `master_list`, `agent_list`, `exhibitor_zk_hosts`, and `bootstrap_url` will be overridden.
- `DCOS_GENERATE_CONFIG_PATH` - Path to DC/OS configuration generation script (default: `dcos_generate_config.sh`)
- `DCOS_INSTALL_METHOD` - One of the following [installation methods](/docs/alternate-install-methods.md) (default: `ssh_pull`):
    - `ssh_pull` - Use the "manual" DC/OS installation method (`dcos_install.sh`) with a pool of thread workers performing remote SHH installation.
    - `ssh_push` - Use the "automated" DC/OS installation method (`dcos_generate_config.sh --deploy`). WARNING: Does not (yet) support agent-public nodes!
    - `web` - Use the GUI DC/OS installation method (`dcos_generate_config.sh --web`). WARNING: Does not (yet) support agent-public nodes!
- `DCOS_JAVA_ENABLED` - Boolean to install java on each agent (default: `false`).  If you set this to true, ensure that there is a jdk install file in your `provision` folder whose name matches `jre-*-linux-x64.*`
- `DCOS_PRIVATE_REGISTRY` - Boolean to install an insecure [private Docker registry](/examples/private-registry.md) on the boot machine and configure the agents to allow it (default: `false`)
- `DCOS_VAGRANT_MOUNT_METHOD` - One of the following methods (default: `virtualbox`):
    - `virtualbox` - Use cross-platform [VirtualBox shared folders](https://www.vagrantup.com/docs/synced-folders/virtualbox.html)
    - `nfs` - Use faster [NFS shared folders](https://www.vagrantup.com/docs/synced-folders/nfs.html).

Additional advanced configuration may be possible by modifying the Vagrantfile directly, but is not encouraged because the internal APIs may change at any time.

# Configure DC/OS

While the `VagrantConfig.yaml` configuration is specific to DC/OS Vagrant, the `config.yaml` content is generic for DC/OS.

## Configure a Proxy

In DC/OS 1.8.5 proxies are allowed to be configured in `config.yaml`.

Make sure that `no_proxy` includes all DC/OS Vagrant VM IPs and any local network addresses you want accessible to the cluster.

Also make sure to update the user, password, and proxy address bellow.

While the example routes https through http, you probably want to use http -> http and https -> https, however this requires your proxy to use a valid SSL certificate.

Example:

```
use_proxy: true
http_proxy: "http://test:testtest@10.0.90.127:3128"
https_proxy: "http://test:testtest@10.0.90.127:3128"
no_proxy:
- "192.168.65.90"
- "192.168.65.95"
- "192.168.65.101"
- "192.168.65.111"
- "192.168.65.121"
- "192.168.65.131"
- "192.168.65.141"
- "192.168.65.151"
- "192.168.65.161"
- "192.168.65.60"
- "192.168.65.70"
- "192.168.65.50"
```

Remember, `config.yaml` cannot be changed after your cluster is deployed!
