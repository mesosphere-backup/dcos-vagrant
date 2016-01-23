DCOS Vagrant
==================

Quickly provision a DCOS cluster on a local machine for development, testing, or demonstration.


# Table of Contents

- [Audience](#audience)
- [Goals](#goals)
- [Requirements](#requirements)
- [Setup](#setup)
- [Deploy](#deploy)
- [Repo Structure](#repo-structure)
- [Appendix](#appendix)


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
- [Packer](https://www.packer.io/)
- [Git](https://git-scm.com/)
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples

## Tested On

- MacBook Pro (Retina, 13-inch, Early 2015), 2.7 GHz Intel Core i5, 16GB Memory
- Deploying single framework(s), cassandra.
- Deploying applications in the repo - spring.json, stress.json, oinker.json and router.json

## Supported DCOS Versions

- CM.4
- CM.5 (1.5)


# Setup

1. Install & Configure Vagrant & VirtualBox

    This repo assumes vagrant and virtualbox are installed and configured to work together.

    See the [Appendix](#appendix) for details about the DCOS-Vagrant cluster architecture.

2. Clone This Repo

   	```bash
   	git clone https://github.com/mesosphere/dcos-vagrant
   	```

3. Build the Packer Box

    Packer is used to build a pre-provisioned virtual machine disk image. This significantly speeds up cluster deployment.

    Note that because the build process uses internet repositories with unversioned requirements, it's not **exactly** reproducible. Each built box may be slightly differen than the last, but deployments using the same box should be exactly the same.

    Use the following commands to build a centos-dcos box:

    ```bash
    cd <repo>/build

    packer build packer-template.json

    cd ..

    vagrant box add dcos build/centos-dcos.box
    ```

4. Configure VirtualBox Networking

    Ensure the internal private network for the cluster is configured to the 192.168.65.0/24 subnet.

    Use the following command to create it on the vboxnet0 interface.

    ```bash
    VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
    ```

    ![Vagrant Network Settings](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/vbox_network.png?raw=true)

5. Update Routable Hosts

   Copy etc/hosts.file to your local hosts file (/etc/hosts)

   	```bash
   	cp <repo>/etc/hosts.file /etc/hosts
   	```

6. Download the DCOS Installer

    Download dcos_generate_config.sh to the root of the repo (the repo will be mounted into the vagrant machines as `/vagrant`).

    **Important**: Contact your sales representative or <sales@mesosphere.com> to obtain the DCOS setup file.

7. Configure the DCOS Machine Types

    Copy one of the example VagrantConfig files:

    ```bash
    cd <repo>
    cp VagrantConfig.yaml.example VagrantConfig.yaml
    ```

    Update `VagrantConfig.yaml` to match your requirements (e.g. cpus, memory). Some frameworks (e.g. cassandra) may require more nodes/resources than others.

    **IMPORTANT**: Make sure your local machine has enough memory to launch all your desired VMs, otherwise your machine may lock up as all the memory is consumed.


# Deploy

The following steps will walk through DCOS and DCOS Apps/Service.

## Deploy DCOS

DCOS can be deployed with 1, 3, or 5 master nodes and any number of public and/or private worker nodes.

In order to deploy DCOS, a bootstrap node is also required to facilitate installation configuration, install file distribution, and zookeeper bootstrapping.

**The number of master nodes must be configured explicitly by defining the `DCOS_CONFIG` environment variable. Several example configurations exist in the `<repo>/etc/` directory. CM.4 and earlier require json configuration. CM.5 and later require yaml configuration.**

Single-master mode uses the default configuration, but can be specified explicitly with `export DCOS_CONFIG=etc/1_master-config.json`.

Multi-master mode must be explicitly configured with `export DCOS_CONFIG=etc/3_master-config.json`.

Remote configurations can also be specified by URL with `export DCOS_CONFIG=http://example.com/5_master-config.json`.

### Minimal Cluster

This is a minimal configuration and will not support robust demos or deployments. Sample applications should work but not most frameworks.

```bash
vagrant up boot m1 w1
```

### Small Cluster

```bash
vagrant up boot m1 w1 w2 lb
```

### Medium Cluster

```bash
vagrant up boot m1 m2 m3 w1 w2 w3 w4 lb
```

### Large Cluster

```bash
vagrant up boot m1 m2 m3 m4 m5 w1 w2 w3 w4 w5 w6 lb
```

## Deploy DCOS Services

Once DCOS is installed, services can be installed using the DCOS CLI as a package manager. In order to install the DCOS CLI itself, follow the instructions in the popup when first visiting the DCOS dashboard (http://m1.dcos/). For more information, see the [DCOS CLI Docs](https://docs.mesosphere.com/administration/introcli/).

For example, the following installs cassandra (which requires at least 3 private worker nodes):

```bash
dcos package install cassandra
```

## Deploy Marathon Apps

Marathon apps can be installed by using the [dcos cli marathon plugin](https://docs.mesosphere.com/administration/introcli/command-reference/#scrollNav-2).

For example, see the [Java-Spring Example App](./examples/java-spring/).


# Repo Structure

**NOTE: Take note of the files in [.gitignore](./.gitignore) which will not be committed. These are indicated by angle brackets below. Some of them must be provided for deployment to succeed.**

	.
	├── build
	│   │
	│   ├── bin                        # Base setup scripts
	│   │   ├── cleanup.sh             # Build script to cleanup build artifacts
	│   │   ├── dcos-deps.sh           # Build script to install DCOS-specific requirements
	│   │   ├── docker.sh              # Build script to configure, install, enable, and start docker-engine
	│   │   ├── os.sh                  # Build script to upgrade CentOS
	│   │   ├── vagrant.sh             # Build script to install Vagrant-specific VM features
	│   │   ├── virtualbox.sh          # Build script to install VirtualBox-specific VM features
	│   │   └── zerodisk.sh            # Build script to improve VirtualBox image compression
	│   │
	│   ├── http                       # Artifact repo for packer build process (kickstart, etc.)
	│   │   └── ks.cfg                 # Kickstart definition for base image provisioning
	│   │
	│   ├── Dockerfile                 # Docker file for java-spring applications
	│   └── packer_template.json       # Template for creating base image using packer
	│
	├─── docs                          # Misc images or supporting documentation
	│
	├─── etc
	│   ├── 1_master-config.json       # DCOS config for 1 master (CM.4)
	│   ├── 1_master-config.yaml       # DCOS config for 1 master (CM.5)
	│   ├── 3_master-config.json       # DCOS config for 3 masters (CM.4)
	│   ├── hosts.file                 # Resolve instance hosts to IPs
	│   └── ip-detect                  # Script for pulling appropriate ip. Be sure to confirm interface (enp0s8)
	│
	├─── examples                      # Example app/service definitions
	│   ├── java-spring                # Example java-spring Marathon application
	│   │   ├── Dockerfile                 # Docker file for java-spring applications
	│   │   ├── java-spring.json           # Marathon descriptor for standalone java spring application
	│   │   ├── java-spring-docker.json    # Marathon descriptor for docker based java spring application
	│   │   ├── README.md                  # Walk-through about how to deploy the java-spring app
	│   ├── jenkins.json               # Marathon descriptor for standalone jenkins, not currently functioning
	│   ├── oinker.json                # Marathon descriptor for functioning twitter clone, use with cassandra
	│   └── stress.json                # Marathon descriptor for standalone commandline which uses CPU
	│
	├── provision
	│   │
	│   ├── bin
	│   │   ├── boot.sh                # Provision script for "boot" type machines
	│   │   ├── hosts.sh               # Base provision script to synchronize /etc/hosts
	│   │   ├── master.sh              # Provision script for "master" type machines
	│   │   ├── worker-private.sh      # Provision script for "worker-private" type machines
	│   │   └── worker-public.sh       # Provision script for "worker-public" type machines
	│   │
	│   ├── gs-spring-boot-0.1.0.jar   # (Optional) standalone java application (requires jre 8.1)
	│   └── <jre-8u66-linux-x64.tgz>   # (Optional) Java Runtime Environment (Download from Oracle)
	│
	├── <dcos_generate_config.sh>      # (Required) DCOS installer from Mesosphere
	├── README.md
	├── <VagrantConfig.yaml>           # (Required) Machine resource definitions
	├── VagrantConfig.yaml.example     # Used to define vagrant instances. Copy to VagrantConfig.yaml
	└── VagrantFile                    # Used to deploy various nodes (boot, masters and workers)


# Appendix

## Vagrant Setup (Virtual Box)

**Networking**

- NatNetwork
 - DHCP
 - 10.0.1.0/24
 - No static port forwarding

- vboxnet0 
 - No DHCP
 - IP4 Address 192.168.65.1
 - Netmask 255.255.255.0

### Vagrant Setup Diagram

![Vagrant Diagram](https://github.com/mesosphere/dcos-vagrant-demo/blob/master/docs/dcos_vagrant_setup.png?raw=true)


# License and Author

Author:: Stathy Touloumis, Karl Isenberg

CreatedBy:: Stathy Touloumis (<stathy@mesosphere.com>)

Copyright:: 2016, Mesosphere

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

