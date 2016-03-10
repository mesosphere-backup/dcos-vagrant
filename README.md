DCOS Vagrant
==================

Quickly provision a DCOS cluster on a local machine for development, testing, or demonstration.

Deploying dcos-vagrant involves creating a local cluster of VirtualBox VMs using the [dcos-vagrant-box](https://github.com/mesosphere/dcos-vagrant-box) base image and then installing [DCOS](https://mesosphere.com/learn/).


# Table of Contents

- [Audience](#audience)
- [Goals](#goals)
- [Requirements](#requirements)
- [Setup](#setup)
- [Deploy](#deploy)
- [Appendix: Authentication](#appendix-authentication)
- [Appendix: Architecture](#appendix-architecture)
- [Appendix: Installation](#appendix-installation)
- [Appendix: Install Ruby](#install-ruby)
- [Appendix: Options](#appendix-options)
- [Appendix: Repo Structure](#appendix-repo-structure)
- [Appendix: VirtualBox Guest Additions](#appendix-virtualbox-guest-additions)
- [License and Author](#license-and-author)

**Other Docs:**

- [Base OS Image](./build)
- [Examples](./examples)
- [DCOS CLI](./docs/dcos-cli.md)
- [Troubleshooting](./docs/troubleshooting.md)


# Audience

- Developers
  - DCOS
  - DCOS Services
  - Mesos Frameworks
  - Marathon Apps
- Continuous Integration (testing)
- Sales Engineers (demos)
- Prospective Customers/Users (kick the tires)


# Goals

- Enable **free**, **local** demonstration of the core capabilities of DCOS
- Deploy, test, and debug development versions of DCOS Services, Mesos Frameworks, and Marathon Apps
- Deploy, test, and debug development versions of DCOS itself
- Decrease the cycle time from local code-change to deployment and testing
- Support multiple use cases to facilitate sharing of pain and gain
- Stay as close to the process of production deployment as possible to reduce maintenance cost of multiple deployment methods
- Facilitate onboarding of new DCOS users by preferring intuitive usability over complex configuration
- Facilitate customization of virtualized machine resources to emulate diverse environments


# Requirements

- [Git](https://git-scm.com/) - clone repo
- [Vagrant](https://www.vagrantup.com/) (>= 1.8.1) - virtualization orchestration
- [VirtualBox](https://www.virtualbox.org/) (>= 4.3) - virtualization engine
  - [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) - manage /etc/hosts
  - (Optional) [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest) - manage vbox guest additions
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples


## Tested On

- MacBook Pro (Retina, 13-inch, Early 2015), 2.7 GHz Intel Core i5, 16GB Memory
- Deploying [Oinker-Go](https://github.com/mesosphere/oinker-go) on [Kubernetes](https://github.com/mesosphere/kubernetes-mesos), depending on [Cassandra](https://github.com/mesosphere/cassandra-mesos)
- Deploying example [Marathon](https://mesosphere.github.io/marathon/) applications (e.g spring.json, stress.json, oinker.json and router.json)

## Supported DCOS Versions

- 1.6.x
  - Requires dcos-vagrant >= 0.4.0
  - Requires flattened yaml config (e.g. <./etc/config-1.6.yaml>)
- 1.5.x
  - Requires dcos-vagrant >= 0.3.0
  - Requires yaml config (e.g. <./etc/config-1.5.yaml>)
- CM.4
  - Requires [dcos-vagrant v0.3.0](https://github.com/mesosphere/dcos-vagrant/tree/v0.3.0)


# Setup

1. Install & Configure Vagrant & VirtualBox

    This repo assumes Vagrant and VirtualBox are installed and configured to work together.

    See [Appendix: Architecture](#appendix-architecture) for details about the DCOS-Vagrant cluster architecture.

1. Clone This Repo

    ```bash
    git clone https://github.com/mesosphere/dcos-vagrant
    ```

1. Configure VirtualBox Networking

    Configure the host-only `vboxnet0` network to use the 192.168.65.0/24 subnet.
    
    1. Create the `vboxnet0` network if it does not exist:
    
        ```bash
        VBoxManage list hostonlyifs | grep vboxnet0 -q || VBoxManage hostonlyif create
        ```

    1. Set the `vboxnet0` subnet:

        ```
        VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
        ```

1. Install Vagrant Host Manager Plugin

    The [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) manages the `/etc/hosts` on the VMs and host to allow access by hostname.

    ```bash
    vagrant plugin install vagrant-hostmanager
    ```

    This will update `/etc/hosts` every time VMs are created or destroyed.

    To avoid entering your password on `vagrant up` & `vagrant destroy` you may enable [passwordless sudo](https://github.com/smdahlen/vagrant-hostmanager#passwordless-sudo).

1. Download the DCOS Installer

    Download `dcos_generate_config.sh` to the root of the repo (the repo will be mounted into the vagrant machines as `/vagrant`).

    If you have multiple `dcos_generate_config.sh` files downloaded you can name them differently and specify which to use with `DCOS_GENERATE_CONFIG_PATH` (e.g. `export DCOS_GENERATE_CONFIG_PATH=dcos_generate_config-1.5-EA.sh`).

    **Important**: Contact your sales representative or <sales@mesosphere.com> to obtain the DCOS setup file.

1. <a name="configure-the-dcos-installer"></a>Configure the DCOS Installer

   Select a config file template based on the downloaded version of DCOS (select one):

   - DCOS 1.6: `export DCOS_CONFIG_PATH=etc/config-1.6.yaml`
   - DCOS 1.5: `export DCOS_CONFIG_PATH=etc/config-1.5.yaml` (default)

   The path to the config file is relative to the repo dir, because the repo dir will be mounted as `/vagrant` within each VM.
   Alternate configurations may be added to the `<repo>/etc/` dir and configured in a similar manner.

   Alternatively, a URL to an online config can be specified (e.g. `export DCOS_CONFIG_PATH=http://example.com/config.yaml`).

1. Configure the DCOS Machine Types

    Copy one of the example VagrantConfig files:

    ```bash
    cd <repo>
    cp VagrantConfig.yaml.example VagrantConfig.yaml
    ```
    
    Update `VagrantConfig.yaml` to match your requirements (e.g. cpus, memory). Some frameworks (e.g. cassandra) may require more nodes/resources than others. This file just defines the machines available - you don't have to launch all these at once, so the example file is a good start.


# Deploy

The following steps will walk through DCOS and DCOS Apps/Service.

## Deploy VMs and Install DCOS

DCOS can be deployed with 1, 3, or 5 master nodes and any number of public and/or private agent nodes.

A bootstrap node is also required, and must be provisioned after all other master and agent nodes.

**IMPORTANT**: Make sure your local machine has enough memory to launch all your desired VMs, otherwise your machine may lock up as all the memory is consumed.

For more details about how DCOS is installed and how to debug deployment/installation failure, see [Appendix: Installation](#appendix-installation).

### Minimal Cluster

A minimal cluster supports launching small Marathon apps. Most other frameworks will fail to install, because they require more than one agent node.

Requires > 4.5GB free memory (using the example [VagrantConfig](./Vagrantconfig.yaml)).

```bash
vagrant up m1 a1 boot
```

### Small Cluster

A small cluster supports running tasks on multiple nodes.

Requires > 7.25GB free memory (using the example [VagrantConfig](./Vagrantconfig.yaml)).

```bash
vagrant up m1 a1 a2 p1 boot
```

### Medium Cluster

A medium cluster supports the installation of a [minimally configured Cassandra](./examples/oinker#install-cassandra).

Requires > 10GB free memory (using the example [VagrantConfig](./Vagrantconfig.yaml)).

```bash
vagrant up m1 a1 a2 a3 a4 p1 boot
```

### Large Cluster

Requires > 17GB free memory (using the example [VagrantConfig](./Vagrantconfig.yaml)).

A large cluster supports master node fail over, multiple framework installs, and multiple public load balancers.

```bash
vagrant up m1 m2 m3 a1 a2 a3 a4 a5 a6 p1 p2 p3 boot
```

## Install DCOS Services

Once DCOS is installed, services can be installed using the DCOS CLI as a package manager. In order to install the DCOS CLI itself, follow the instructions in the popup when first visiting the DCOS dashboard (http://m1.dcos/). For more information, see the [DCOS CLI Docs](https://docs.mesosphere.com/administration/introcli/).

For example, the following installs cassandra (which requires at least 3 private agent nodes):

```bash
dcos package install cassandra
```

## Install Marathon Apps

Marathon apps can be installed by using the [dcos cli marathon plugin](https://docs.mesosphere.com/administration/introcli/command-reference/#scrollNav-2).

For example, see [Oinker on Marathon](./examples/oinker/) or the [Java-Spring Example App](./examples/java-spring/).

## Install Kubernetes Apps

Kubernetes apps can be installed by using the [dcos cli kubectl plugin](https://github.com/mesosphere/dcos-kubectl).

For example, see the [Oinker on Kubernetes Example](./examples/kube-oinker/).


# Appendix: Authentication

When installing the Enterprise Edition of DCOS (>= 1.6) on dcos-vagrant, the cluster will prompt for a username and password when using the dcos-cli or the web dashboard.

If you're using the provided 1.6 installer config file ([etc/config-1.6.yaml](./etc/config-1.6.yaml)) then the superuser credentials are by default `admin`/`admin`.


# Appendix: Architecture

**Networking**

- NatNetwork
  - DHCP
  - 10.0.1.0/24
  - No static port forwarding

- vboxnet0
  - No DHCP
  - IP4 Address 192.168.65.1
  - Netmask 255.255.255.0

## Architecture Diagram

![Vagrant Diagram](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/dcos_vagrant_setup.png?raw=true)


# Appendix: Installation

The DCOS installation is multi-stage with many moving parts. 

## High Level Stages

1. Node machines are created and provisioned (master, agent-private, agent-public)
    1. Nodes are given IPs and added to a shared network
    1. SSH keys are updated
    1. SSL certificate authorities are updated
    1. Docker is configured to allow insecure registries (if configured)
1. Boot machine is created and provisioned
    1. Bootstrap Exhibitor (Zookeeper) is started
    1. Nginx is started to host generated node config artifacts
    1. Private Docker registry is started (if configured)
    1. Java runtime is copied from host and installed (if configured)
    1. DCOS release (`dcos_generate_config.sh`) is copied from host
1. DCOS pre-install
    1. DCOS release config (`config.yaml` & `ip-detect`) is generated from list of active nodes
    1. DCOS node config artifacts (`dcos_install.sh` & tarballs) are generated from the release and release config
1. DCOS install
    1. Node config artifacts are distributed to the nodes and installed (based on node type)
    1. DCOS systemd services are started on the nodes
1. DCOS post-install
    1. Exhibitor starts, brings up Zookeeper
    1. Mesos Master starts up and registers with Zookeeper
    1. Mesos DNS detects Mesos Master using Zookeeper and initializes `leader.mesos`
    1. Root Marathon detects `leader.mesos` and starts up
        1. Root Marathon registers with the leading Mesos Master
    1. AdminRouter (nginx) detects `leader.mesos` starts up
        1. DCOS, Mesos, Marathon, and Exhibitor UIs become externally accessible
    1. Mesos Slaves detect `leader.mesos` and start up
        1. Mesos Slaves register with the leading Mesos Master
        1. DCOS Nodes become visible in the DCOS UI

## System Logs

Ideally deployment and installation failures will be visible in the vagrant output, but sometimes failures occur in the background. This is especially true for systemd components that come up concurrently and wait for dependencies to come up.

To interrogate the system, it's possible to ssh into the machines using `vagrant ssh <machine>` and view the logs of all system components with `joutnalctl -f`. 


# Appendix: Install Ruby

Installing vagrant plugins may require having an modern version of ruby installed on the host. 

There are several ways to install ruby. One way is to use ruby-install, using chruby to manage your ruby installations:

1. Install ruby-install via homebrew:

    ```
    brew install ruby-install
    ```

1. Install ruby 2.2 via ruby-install:

    ```
    ruby-install ruby 2.2
    ```

1. Install chruby via homebrew:

    ```
    brew install chruby
    ```

1. Configure your shell (and `~/.bash_profile`) to source chruby:

    ```
    source '/usr/local/share/chruby/chruby.sh'
    chruby 2.2
    ```


# Appendix: Options

There are several configurable options when deploying a cluster and installing DCOS on it. Most of them are configurable via environment variables:

- `DCOS_BOX` - VirtualBox box image name (default: `mesosphere/dcos-centos-virtualbox`)
- `DCOS_BOX_URL` - VirtualBox box image url or vagrant-cloud style image repo (default: `https://downloads.mesosphere.com/dcos-vagrant/metadata.json`)
- `DCOS_BOX_VERSION` - VirtualBox box image version (default: `~> 0.4.1`)
- `DCOS_MACHINE_CONFIG_PATH` - Path to virtual machine configuration manifest (default: `VagrantConfig.yaml`)
    - Must contain at least one `boot` type machine, one `master` type machine, and one `agent` or `agent-public` type machine.
- `DCOS_CONFIG_PATH` - Path to DCOS configuration template (default: `etc/config.yaml`)
    - `master_list`, `agent_list`, `exhibitor_zk_hosts`, and `bootstrap_url` will be overridden.
- `DCOS_GENERATE_CONFIG_PATH` - Path to DCOS configuration generation script (default: `dcos_generate_config.sh`)
- `DCOS_INSTALL_METHOD` - One of the following methods (default: `ssh_pull`):
    - `ssh_pull` - Use the "manual" DCOS installation method (`dcos_install.sh`) with a pool of thread workers performing remote SHH installation.
    - `ssh_push` - Use the "automated" DCOS installation method (`dcos_generate_config.sh --deploy`). WARNING: Does not (yet) support agent-public nodes!
- `DCOS_JAVA_ENABLED` - Boolean to install java on each agent (default: `false`)
- `DCOS_PRIVATE_REGISTRY` - Boolean to install an insecure private Docker registry on the boot machine and configure the agents to allow it (default: `false`)

Additional advanced configuration may be possible by modifying the Vagrantfile directly, but is not encouraged because the internal APIs may change at any time.


# Appendix: Repo Structure

**NOTE: Take note of the files in [.gitignore](./.gitignore) which will not be committed. These are indicated by angle brackets below. Some of them must be provided for deployment to succeed.**

	.
	├─── docs                          # Misc images or supporting documentation
	│
	├─── etc
	│   ├── config-1.5.yaml            # DCOS config template (1.5)
	│   └── config-1.6.yaml            # DCOS config template (1.6)
	│
	├─── examples                      # Example app/service definitions
	│   ├── java-spring                # Example java-spring Marathon application
	│   ├── kube-oinker                # Example twitter clone on Kubernetes
	│   ├── oinker                     # Example twitter clone on Marathon
	│   ├── jenkins.json               # Marathon descriptor for standalone jenkins, not currently functioning
	│   └── stress.json                # Marathon descriptor for standalone commandline which uses CPU
	│
	├── provision
	│   │
	│   ├── bin
	│   │   ├── ca-certificates.sh     # Provision certificate authorities
	│   │   ├── insecure-registry.sh   # Provision docker daemon to accept the private registry
	│   │   ├── type-agent-private.sh  # Provision script for "agent-private" type machines
	│   │   ├── type-agent-public.sh   # Provision script for "agent-public" type machines
	│   │   ├── type-boot.sh           # Provision script for "boot" type machines
	│   │   └── type-master.sh         # Provision script for "master" type machines
	│   │
	│   ├── gs-spring-boot-0.1.0.jar   # (Optional) standalone java application (requires jre 8.1)
	│   └── <jre-8u66-linux-x64.tgz>   # (Optional) Java Runtime Environment (Download from Oracle)
	│
	├── <dcos_generate_config.sh>      # (Required) DCOS installer from Mesosphere
	├── README.md
	├── <VagrantConfig.yaml>           # (Required) Machine resource definitions
	├── VagrantConfig.yaml.example     # Used to define node types. Copy to VagrantConfig.yaml
	└── VagrantFile                    # Used to deploy nodes and install DCOS


# Appendix: VirtualBox Guest Additions

Ideally, the vagrant box image used by dcos-vagrant includes VirtualBox Guest Additions compatible with the latest versions of VirtualBox. It should "just work".

However, if they are out of date or incompatible with your installed version of VirtualBox you may want to install the [VBGuest Vagrant Plugin](https://github.com/dotless-de/vagrant-vbguest) to automatically install VirtualBox Guest Additions appropriate to your local VirtualBox version on each new VM after it is created.

## Install

```bash
vagrant plugin install vagrant-vbguest
```

This allows the pre-built vagrant box image to work on multiple (past and future) versions of VirtualBox.


# License and Author

Copyright:: 2016 Mesosphere, Inc.

The contents of this repository are solely licensed under the terms described in the [LICENSE file](./LICENSE) included in this repository.

Authors are listed in [AUTHORS.md file](./AUTHORS.md).
