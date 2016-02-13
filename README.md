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
- [Appendix: Architecture](#appendix-architecture)
- [Appendix: Installation](#appendix-installation)
- [Appendix: Repo Structure](#appendix-repo-structure)
- [Appendix: Troubleshooting](#appendix-troubleshooting)
- [License and Author](#license-and-author)

**Other Docs:**

- [Base OS Image](./build)
- [Examples](./examples)


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

- [Vagrant](https://www.vagrantup.com/) (>= 1.8.1)
- [VirtualBox](https://www.virtualbox.org/) (>= 4.3)
  - [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager)
  - [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest)
- [Git](https://git-scm.com/)
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples


## Tested On

- MacBook Pro (Retina, 13-inch, Early 2015), 2.7 GHz Intel Core i5, 16GB Memory
- Deploying [Oinker-Go](https://github.com/mesosphere/oinker-go) on [Kubernetes](https://github.com/mesosphere/kubernetes-mesos), depending on [Cassandra](https://github.com/mesosphere/cassandra-mesos)
- Deploying example [Marathon](https://mesosphere.github.io/marathon/) applications (e.g spring.json, stress.json, oinker.json and router.json)

## Supported DCOS Versions

- 1.6
  - Requires dcos-vagrant >= 0.4.0
  - Requires flattened yaml config (e.g. <./etc/1_master-config-1.6.yaml>)
- 1.5.x
  - Requires dcos-vagrant >= 0.3.0
  - Requires yaml config (e.g. <./etc/1_master-config-1.5.yaml>)
- CM.4
  - Requires [dcos-vagrant v0.3.0](https://github.com/mesosphere/dcos-vagrant/tree/v0.3.0)


# Setup

1. Install & Configure Vagrant & VirtualBox

    This repo assumes vagrant and virtualbox are installed and configured to work together.

    See [Appendix: Architecture](#appendix-architecture) for details about the DCOS-Vagrant cluster architecture.

1. Clone This Repo

    ```bash
    git clone https://github.com/mesosphere/dcos-vagrant
    ```

1. Configure VirtualBox Networking

    Ensure the internal private network for the cluster is configured to the 192.168.65.0/24 subnet.

    Use the following command to create it on the vboxnet0 interface.

    ```bash
    VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
    ```

    ![Vagrant Network Settings](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/vbox_network.png?raw=true)

1. Install Vagrant Host Manager Plugin

    The [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) manages the `/etc/hosts` on the VMs and host to allow access by hostname.

    ```bash
    vagrant plugin install vagrant-hostmanager
    ```

    This will update `/etc/hosts` every time VMs are created or destroyed.

    To avoid entering your password on `vagrant up` & `vagrant destroy` you may enable [passwordless sudo](https://github.com/smdahlen/vagrant-hostmanager#passwordless-sudo).

1. Install Vagrant VBGuest Plugin

    The [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest) manages automatically installing VirtualBox Guest Additions appropriate to your local Vagrant version on each new VirtualBox VM as it is created.

    ```bash
    vagrant plugin install vagrant-vbguest
    ```

    This allows the pre-built vagrant box image to work on multiple (and future) versions of VirtualBox.

1. Download the DCOS Installer

    Download `dcos_generate_config.sh` to the root of the repo (the repo will be mounted into the vagrant machines as `/vagrant`).

    If you have multiple `dcos_generate_config.sh` files downloaded you can name them differently and specify which to use with `DCOS_GENERATE_CONFIG_PATH` (e.g. `export DCOS_GENERATE_CONFIG_PATH=dcos_generate_config-1.5-EA.sh`).

    **Important**: Contact your sales representative or <sales@mesosphere.com> to obtain the DCOS setup file.

1. <a name="configure-the-dcos-installer"></a>Configure the DCOS Installer

   By default, the single-master json (DCOS 1.4) DCOS installer configuration is used.

   DCOS versions <= 1.4 require a json config. DCOS versions >= 1.5 require a yaml config.

   **If you're using DCOS 1.5 or higher, or want a multiple-master cluster, the `DCOS_CONFIG_PATH` environment variable must be set.**

   Included config files (select one):

   - DCOS 1.6 1-master: `export DCOS_CONFIG_PATH=etc/1_master-config-1.6.yaml`
   - DCOS 1.5 1-master: `export DCOS_CONFIG_PATH=etc/1_master-config-1.5.yaml` (default)
   - DCOS 1.4 1-master: `export DCOS_CONFIG_PATH=etc/1_master-config-1.4.json`
   - DCOS 1.4 3-master: `export DCOS_CONFIG_PATH=etc/3_master-config-1.4.json`

   The path to the config file is relative to the repo dir, because the repo dir will be mounted as `/vagrant` within each VM.
   Other configurations can be added to the `<repo>/etc/` dir and configured in a similar manner.

   Alternatively, a URL to an online config can be specified (e.g. `export DCOS_CONFIG_PATH=http://example.com/5_master-config.json`).

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

DCOS can be deployed with 1, 3, or 5 master nodes and any number of public and/or private agent nodes, depending on the DCOS installer configuration. See [Configure the DCOS Installer](#configure-the-dcos-installer) for more details.

In order to deploy DCOS, a bootstrap node is also required to facilitate installation configuration, install file distribution, and zookeeper bootstrapping.

**IMPORTANT**: Make sure your local machine has enough memory to launch all your desired VMs, otherwise your machine may lock up as all the memory is consumed.

For more details about how DCOS is installed and how to debug deployment/installation failure, see [Appendix: Installation](#appendix-installation).

### Minimal Cluster

This is a minimal configuration and will not support robust demos or deployments. Sample applications should work but not most frameworks.

```bash
vagrant up boot m1 a1
```

### Small Cluster

```bash
vagrant up boot m1 a1 a2 p1
```

### Medium Cluster

```bash
vagrant up boot m1 m2 m3 a1 a2 a3 a4 p1
```

### Large Cluster

```bash
vagrant up boot m1 m2 m3 m4 m5 a1 a2 a3 a4 a5 a6 p1
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

1. Boot node unpacks `dcos_generate_config.sh`, creates `dcos_install.sh`, starts an nginx on `boot.dcos` to distribute the installer, and a bootstrap zookeeper required by Exibitor
1. Master nodes are provisioned using `dcos_install.sh master`
    1. Exibitor starts, brings up Zookeeper
    1. Mesos Master starts up and registers with Zookeeper
    1. Mesos DNS detects Mesos Master using Zookeeper and initializes `leader.mesos` 
    1. Root Marathon detects `leader.mesos` and comes up
    1. AdminRouter (nginx) starts routing subpaths of `leader.mesos` to various components
1. Agent nodes are provisioned using `dcos_install.sh slave` or `dcos_install.sh slave_public`
    1. Mesos Slave finds the leading Mesos Master using Zookeeper and Mesos DNS

## System Logs

Ideally deployment and installation failures will be visible in the vagrant output, but sometimes failures occur in the background. This is especially true for systemd components that come up concurrently and wait for dependencies to come up.

To interrogate the system, it's possible to ssh into the machines using `vagrant ssh <machine>` and view the logs of all system components with `joutnalctl -f`. 


# Appendix: Repo Structure

**NOTE: Take note of the files in [.gitignore](./.gitignore) which will not be committed. These are indicated by angle brackets below. Some of them must be provided for deployment to succeed.**

	.
	├─── docs                          # Misc images or supporting documentation
	│
	├─── etc
	│   ├── 1_master-config-1.4.json   # DCOS config for 1 master (CM.4)
	│   ├── 1_master-config-1.5.yaml   # DCOS config for 1 master (1.5)
	│   ├── 1_master-config-1.6.yaml   # DCOS config for 1 master (1.6)
	│   └── 3_master-config-1.4.json   # DCOS config for 3 masters (1.4)
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


# Appendix: Troubleshooting

Common errors when bringing up the cluster, and their solutions.

- **Problem:** `The following settings shouldn't exist: env`

    **Solution**: [Upgrade Vagrant](https://www.vagrantup.com/downloads.html) to >= 1.8.1 (Ubuntu's package manager repos are out of date, install manually).

- **Problem:** `Specified config file '/genconf/config.yaml' does not exist`

    **Solution**: DCOS >= 1.5 requires a yaml config file, not json (used by prior versions of DCOS). Make sure the `DCOS_CONFIG_PATH` environment variable points to a file with the correct format for your DCOS version before running vagrant:

    ```
    export DCOS_CONFIG_PATH=etc/1_master-config-1.5.yaml
    ```

- **Problem**
    ```
    Configuration generation (--genconf) requires the following errors to be fixed:
    dcos_installer:: exhibitor_zk_hosts
    dcos_installer:: master_list
    ```

    **Solution**: DCOS >= 1.6 requires a flattened yaml config file. Make sure the `DCOS_CONFIG_PATH` environment variable points to a file with the correct schema for your DCOS version before running vagrant:

    ```
    export DCOS_CONFIG_PATH=etc/1_master-config-1.6.yaml
    ```


# License and Author

Copyright:: 2016 Mesosphere, Inc.

The contents of this repository are solely licensed under the terms described in the [LICENSE file](./LICENSE) included in this repository.

Authors are listed in [AUTHORS.md file](./AUTHORS.md).
