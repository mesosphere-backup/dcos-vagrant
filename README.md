DC/OS Vagrant
==================

Quickly provision a DC/OS cluster on a local machine for development, testing, or demonstration.

Deploying dcos-vagrant involves creating a local cluster of VirtualBox VMs using the [dcos-vagrant-box](https://github.com/dcos/dcos-vagrant-box) base image and then installing [DC/OS](https://dcos.io/).

**Issue tracking is moving to the [DCOS JIRA](https://dcosjira.atlassian.net/) ([dcos-vagrant component](https://dcosjira.atlassian.net/issues/?jql=project%20%3D%20DCOS%20AND%20component%20%3D%20dcos-vagrant)).
Issues on Github will be disabled soon.**


# Table of Contents

- [Audience](#audience)
- [Goals](#goals)
- [Requirements](#requirements)
- [Deploy](#deploy)
- [Configure](#configure)
- [Upgrade](#upgrade)
- [Destroy](#destroy)
- [Example Clusters](#example-clusters)
- [Environment Options](#environment-options)
- [License and Author](#license-and-author)

**Other Docs:**

- [Architecture](./docs/architecture.md)
- [DC/OS Installation](./docs/dcos-installation.md)
- [Install Ruby](./docs/install-ruby.md)
- [Repo Structure](./docs/repo-structure.md)
- [Examples](./examples)
- [DC/OS CLI](./docs/dcos-cli.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [VirtualBox Guest Additions](./docs/virtualbox-guest-additions.md)


# Audience

- Developers
  - DC/OS
  - DC/OS Services
  - Mesos Frameworks
  - Marathon Apps
- Continuous Integration (testing)
- Sales Engineers (demos)
- Prospective Customers/Users (kick the tires)


# Goals

- Enable **free**, **local** demonstration of the core capabilities of DC/OS
- Deploy, test, and debug development versions of DC/OS Services, Mesos Frameworks, and Marathon Apps
- Deploy, test, and debug development versions of DC/OS itself
- Decrease the cycle time from local code-change to deployment and testing
- Support multiple use cases to facilitate sharing of pain and gain
- Stay as close to the process of production deployment as possible to reduce maintenance cost of multiple deployment methods
- Facilitate onboarding of new DC/OS users by preferring intuitive usability over complex configuration
- Facilitate customization of virtualized machine resources to emulate diverse environments


# Requirements

## Hardware

**Minimum**:

- 5GB free memory (8GB system memory)

Most services *cannot* be installed on the Minimal cluster.

**Recommended (Medium)**:

- 10GB free memory (16GB system memory)

Most services *can* be installed on the Medium cluster, but not all at the same time.

## Software

- [Git](https://git-scm.com/) - clone repo
- [Vagrant](https://www.vagrantup.com/) (>= 1.8.1) - virtualization orchestration
  - [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) - manage /etc/hosts
  - (Optional) [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest) - manage vbox guest additions
- [VirtualBox](https://www.virtualbox.org/) (>= 4.3) - virtualization engine
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples

## Supported DC/OS Versions

[DC/OS Downloads &amp; Release Notes](https://dcos.io/releases/)

- 1.7.x
  - Requires dcos-vagrant >= 0.6.0
  - No config changes since 1.6 (e.g. [config-1.7.yaml](etc/config-1.7.yaml))
- 1.6.x
  - Requires dcos-vagrant >= 0.4.0
  - Requires flattened yaml config (e.g. [config-1.6.yaml](etc/config-1.6.yaml))
- 1.5.x
  - Requires dcos-vagrant >= 0.3.0
  - Requires yaml config (e.g. [config-1.5.yaml](etc/config-1.5.yaml))
- CM.4
  - Requires [dcos-vagrant v0.3.0](https://github.com/dcos/dcos-vagrant/tree/v0.3.0)

The latest version of DC/OS Vagrant usually works with the latest DC/OS Early Access and Stable releases.

To test bleeding-edge Master releases of DC/OS it may be necessary to use the master branch of dcos-vagrant.


# Deploy

1. Install Vagrant & VirtualBox

    For installer links, see [Software Requirements](#software).

1. Clone this Repo

    Select where you want the dcos-vagrant repo to be on your local hard drive and `cd` into it. Then clone the repo using git.

    ```bash
    git clone https://github.com/dcos/dcos-vagrant
    ```

1. Install Vagrant Host Manager Plugin

    The [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) manages the `/etc/hosts` on the VMs and host to allow access by hostname.

    ```bash
    vagrant plugin install vagrant-hostmanager
    ```

    This will update `/etc/hosts` every time VMs are created or destroyed.

    To avoid entering your password on `vagrant up` & `vagrant destroy`, enable [passwordless sudo](https://github.com/smdahlen/vagrant-hostmanager#passwordless-sudo).

    On some versions of Mac OS X, installing vagrant plugins may require [installing a modern version of Ruby](./docs/install-ruby.md).

1. Download the DC/OS Installer

    If you don't already have a DC/OS installer downloaded, you'll need to select and download one of the [supported versions](#supported-dcos-versions).

    Once downloaded, move the installer (`dcos_generate_config.sh`) to the root of the repo (the repo will be mounted into the vagrant machines as `/vagrant`).

    If you have multiple `dcos_generate_config.sh` files downloaded you can name them differently and specify which to use with `DCOS_GENERATE_CONFIG_PATH` (e.g. `export DCOS_GENERATE_CONFIG_PATH=dcos_generate_config-1.5-EA.sh`).

    Enterprise edition installers are also supported. Contact your sales representative or <sales@mesosphere.com> to obtain the right DC/OS installer.

1. <a name="configure-the-dcos-installer"></a>Configure the DC/OS Installer

   Select a config file template based on the downloaded version of DC/OS (select one):

   - DC/OS 1.7: `export DCOS_CONFIG_PATH=etc/config-1.7.yaml`
   - DC/OS 1.6: `export DCOS_CONFIG_PATH=etc/config-1.6.yaml`
   - DC/OS 1.5: `export DCOS_CONFIG_PATH=etc/config-1.5.yaml`

   The path to the config file is relative to the repo dir, because the repo dir will be mounted as `/vagrant` within each VM.
   Alternate configurations may be added to the `<repo>/etc/` dir and configured in a similar manner.

   Alternatively, a URL to an online config can be specified (e.g. `export DCOS_CONFIG_PATH=http://example.com/config.yaml`).

1. Configure the DC/OS Machine Types

    Copy the example VagrantConfig file:

    ```bash
    cd <repo>
    cp VagrantConfig.yaml.example VagrantConfig.yaml
    ```
    
    See [Configure](#configure) for more details on customizing your cluster.

1. (Optional) Download/Update the VM Base Image

    By default, Vagrant should automatically download the latest VM Base Image (virtualbox box) when you run `vagrant up <machines>`, but downloading the image takes a while the first time. You may want to trigger the download or update manually.

    ```
    vagrant box add https://downloads.dcos.io/dcos-vagrant/metadata.json
    ```

    If you already have the latest version downloaded, the above command will fail.

    **Known Issue**: Vagrant's box downloader is [known to be slow](https://github.com/mitchellh/vagrant/issues/5319). If your download is super slow (100-300k/s range), then cancelling the download (Ctrl+C) and restarting it *sometimes* makes it download faster.

1. (Optional) Configure Other Options

    DC/OS Vagrant supports many other [configurable options via environment variables](#environment-options). Skip these for first time use.

1. Deploy DC/OS

    Specify which machines to deploy. For example (requires 5.5GB free memory):

    ```bash
    vagrant up m1 a1 p1 boot
    ```

    Many permutations of machines are possible. See [Example Clusters](#example-clusters) for more options.

    Once the the machines are created and provisioned, DC/OS will be installed. Once complete, the Web Interface will be available at <http://m1.dcos/>.

    See the [DC/OS Usage docs](https://dcos.io/docs/latest/usage/) for more information on how to use you new DC/OS cluster.

1. (Optional) Authentication

    When installing **DC/OS** (>= 1.7) on dcos-vagrant, the cluster will prompt for authentication through Google, Github, or Microsoft. The first user to log in becomes the superuser and must add additional users to allow multiple. It's also possible to [disable login](https://dcos.io/docs/1.7/administration/security/managing-authentication/#authentication-opt-out) in the installation config, if desired.

    When installing **Mesosphere Enterprise DC/OS** (>= 1.6) on dcos-vagrant, the cluster will prompt for a username and password when using the DC/OS CLI or the web dashboard. If you're using the provided 1.6 or 1.7 installer config file then the superuser credentials are by default `admin`/`admin`.


# Configure

The number of machines and their resources is configurable, depending on your needs and hardware constraints.

The [VagrantConfig.yaml.example](VagrantConfig.yaml.example) includes some preset machine configurations that have been chosen to allow the widest possible use cases within a constrained memory environment (e.g. a laptop with 16GB memory). These presets may or may not fit your use case. If they don't, just modify your `VagrantConfig.yaml` file to fit your needs.

Deploying multiple VMs takes a lot of memory and Mesos reserves more for overhead on each node. So don't expect to be able to install every DC/OS service or use production-grade configurations. Most services will require reduced configurations in order to fit within the allocated memory. Some services (e.g. Cassandra) may require more nodes/resources than others.

For more information about how the DC/OS installation works and how to debug deployment/installation failure, see [DC/OS Installation](./docs/dcos-installation.md).

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

# Upgrade

In-place upgrading of DC/OS is not currently supported using DC/OS Vagrant. Existing clusters must be [destroyed](#destroy) before a new one can be created.

For version compatibility, see [Supported DC/OS Versions](#supported-dcos-versions).

**Upgrade to a new version of DC/OS Vagrant**:

1. Change into the repo directory (e.g. `cd ~/workspace/dcos-vagrant`)
1. Fetch the new code (e.g. `git fetch`)
1. Check out the new desired version (e.g. `git checkout v0.6.0` or `git checkout master`)

**Upgrade to a new version of DC/OS**:

1. Download a new release from [DC/OS Releases](https://dcos.io/releases/)
2. Move the new `dcos_generate_config.sh` into the dcos-vagrant repo directory
3. Update the DC/OS config (e.g. `export DCOS_CONFIG_PATH=etc/config-1.7.yaml`)

# Destroy

The following command destroys your cluster and any data stored there:

```
vagrant destroy -f
```

# Example Clusters

Any permutation of machines that fits the above constraints is possible. Below are a few options to try.

## Minimal Cluster

A minimal cluster supports launching small Marathon apps. Most other services will fail to install, because they require more than one agent node.

Requires > 4.5GB free memory (using the example [VagrantConfig](./VagrantConfig.yaml.example)).

```bash
vagrant up m1 a1 boot
```

## Small Cluster

A small cluster supports running tasks on multiple nodes.

Requires > 7.25GB free memory (using the example [VagrantConfig](./VagrantConfig.yaml.example)).

```bash
vagrant up m1 a1 a2 p1 boot
```

## Medium Cluster

A medium cluster supports the installation of a [minimally configured Cassandra](./examples/oinker#install-cassandra).

Requires > 10GB free memory (using the example [VagrantConfig](./VagrantConfig.yaml.example)).

```bash
vagrant up m1 a1 a2 a3 a4 p1 boot
```

## Large Cluster

Requires > 17GB free memory (using the example [VagrantConfig](./VagrantConfig.yaml.example)).

A large cluster supports master node fail over, multiple framework installs, and multiple public load balancers.

```bash
vagrant up m1 m2 m3 a1 a2 a3 a4 a5 a6 p1 p2 p3 boot
```

# Environment Options

There are several configurable options when deploying a cluster and installing DC/OS on it. Most of them are configurable via environment variables:

- `DCOS_BOX` - VirtualBox box image name (default: `mesosphere/dcos-centos-virtualbox`)
- `DCOS_BOX_URL` - VirtualBox box image url or vagrant-cloud style image repo (default: `https://downloads.dcos.io/dcos-vagrant/metadata.json`)
- `DCOS_BOX_VERSION` - VirtualBox box image version (default: `~> 0.5.0`)
- `DCOS_MACHINE_CONFIG_PATH` - Path to virtual machine configuration manifest (default: `VagrantConfig.yaml`)
    - Must contain at least one `boot` type machine, one `master` type machine, and one `agent` or `agent-public` type machine.
- `DCOS_CONFIG_PATH` - Path to DC/OS configuration template (default: `etc/config.yaml`)
    - `master_list`, `agent_list`, `exhibitor_zk_hosts`, and `bootstrap_url` will be overridden.
- `DCOS_GENERATE_CONFIG_PATH` - Path to DC/OS configuration generation script (default: `dcos_generate_config.sh`)
- `DCOS_INSTALL_METHOD` - One of the following methods (default: `ssh_pull`):
    - `ssh_pull` - Use the "manual" DC/OS installation method (`dcos_install.sh`) with a pool of thread workers performing remote SHH installation.
    - `ssh_push` - Use the "automated" DC/OS installation method (`dcos_generate_config.sh --deploy`). WARNING: Does not (yet) support agent-public nodes!
- `DCOS_JAVA_ENABLED` - Boolean to install java on each agent (default: `false`)
- `DCOS_PRIVATE_REGISTRY` - Boolean to install an insecure [private Docker registry](./examples/private-registry.md) on the boot machine and configure the agents to allow it (default: `false`)
- `DCOS_VAGRANT_MOUNT_METHOD` - One of the following methods (default: `virtualbox`):
    - `virtualbox` - Use cross-platform [VirtualBox shared folders](https://www.vagrantup.com/docs/synced-folders/virtualbox.html)
    - `nfs` - Use faster [NFS shared folders](https://www.vagrantup.com/docs/synced-folders/nfs.html).

Additional advanced configuration may be possible by modifying the Vagrantfile directly, but is not encouraged because the internal APIs may change at any time.


# License

Copyright 2016 Mesosphere, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this repository except in compliance with the License.

The contents of this repository are solely licensed under the terms described in the [LICENSE file](./LICENSE) included in this repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
