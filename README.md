DCOS Local Demo using Vagrant and Virtual Box
==================

The purpose of this repo was to create a simple way to quickly provision various DCOS cluster(s) on an internal system. This can optionally provide a model for self-guiding customers in a fairly prescriptive fashion. This is done using the opensource VirtualBox virtualization layer (Oracle) and Vagrant, a tool for easily modeling system deployments against various providers (VirtualBox). The driving goals of the implementation are:

- **KISS - Keep It Simple Stupid:** I prefer explicit/simple configuration over flexible/complex so it's easy to understand.
- **Experiment, Iterate and Test:**
 - Experiment: The more field people can validate with new releases, demos and customer engagements.
 - Iterate: Various config changes can be tried to find better ways they will function and operate.
 - Test: New releases and customer env can be tested more thoroughly ensuring a more positive customer experience.
- **Localized:** Ensure ease of use without network constraints.

**NOTE: Before making changes to your local repo be sure to fork the repo or create a branch. Also, take note of the files in the .gitignore file which will not be committed.**

**Repo Structure**

	.
	├── build
	│   ├── gs-spring-boot-0.1.0.jar   # Simple standalone java application (uploaded to downloads.mesosphere.com)
	│
	├── etc
	│   ├── ip-detect                  # Script for pulling appropriate ip-address. Be sure to confirm interface (enp0s8)
	│   ├── 1_master-config.json       # DCOS config for 1 master
	│   ├── 3_master-config.json       # DCOS config for 3 masters
	│
	├── spring.json (by request) `xx      # Marathon descriptor for standalone java spring application.
	├── stress.json                    # Marathon descriptor for standalone commandline which uses CPU.
	├── oinker.json                    # Marathon descriptor for functioning twitter clone, deploy with router.json
	├── router.json                    # Marathon descriptor for Routing container, deploy with oinker.json
	├── jenkins.json                   # Marathon descriptor for standalone jenkins, not currently functioning.
	├── VagrantFile                    # Used to deploy various nodes (boot, masters and workers)
	├── dcos_generate_config.sh        # This is the core installer for DCOS from Mesosphere.
	└── README.md


**Tested On**
- On a MacBook Pro (Retina, 13-inch, Early 2015), 2.7 GHz Intel Core i5, 15GB Memory
- Deploying single framework(s), cassandra.
- Deploying applications in the repo - spring.json, stress.json, oinker.json and router.json

1) Preparation
------------------

**1a)** Please review the [Appendix](#appendix) section for configuring local system settings, copying files and installing Vagrant + VirtualBox. This repo assumes a functioning vagrant is setup using the virtualbox provider.

**1b)** You'll need to install the following box locally into your Vagrant installation.

> [non-updated OS](https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box) github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box

```bash
vagrant box add new-centos https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box
```

**1c)** You will need to download the dcos_generate_config.sh script locally. Please download the appropriate version for testing and copy directly into the root repo directory.

If you'd like to customize the base OS, you can do so and will need to adjust the following lines in your VagrantFile.

> BOX_NAME = "new-centos"

**1d)** Optionally review the commands to be executed within the VagrantFile. They are specified at the top for 4 core components:
- Base OS for all nodes
- Bootstrap node
- Master node
- Worker node

These commands can be easily extrapolated for a customer engagement as well.

2) Deploy Cluster
------------------

### 2a) Single Master (boot node, master node, 3 x worker nodes)

> NOTE: This is a minimal configuration and will not support robust demos or deployments. Sample application deployments will work but not with frameworks.

```bash
cd <repo>

vi VagrantFile # Uncomment appropriate variable to define config.json eg. DCOS_CONFIG_JSON="1_master-config.json"

vagrant up boot m1 w1 w2 w3
```
> NOTE: This will support a minimal framework and application deployment. It was tested against the oinker app + cassandra.

```bash
vagrant up boot m1 w4 w5 w6
```

### 2b) Multi Master (boot node, 3 x master node, worker node)

> NOTE: This is a minimal configuration and will not support robust demos or deployments. Sample application deployments will work but not with frameworks.

```bash
cd <repo>

vi VagrantFile # Uncomment appropriate variable to define config.json eg. DCOS_CONFIG_JSON="3_master-config.json"

vagrant up boot

vagrant up m1 m2 m3 --no-provision
```

Next, In multiple terminals run the commands simultaneously

```bash
term1# vagrant provision m1
term2# vagrant provision m2
term3# vagrant provision m3
```

Next, deploy the worker node

```bash
vagrant up w1
```

Appendix
==================

### System Setup

1. Get the repo

	```bash
	git clone https://github.com/stathy/dcos-repo
	```

2. Copy etc/hosts.file to your local hosts file (/etc/hosts)

	```bash
	cp <repo>/etc/hosts.file /etc/hosts
	```

3. Download the appropriate dcos_generate_config.sh file from Mesosphere and place into the root repo directory.

4. Install VirtualBox

	> https://www.virtualbox.org/wiki/Downloads

5. Intall Vagrant

	> http://www.vagrantup.com/downloads

### Vagrant Setup (Virtual Box)

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

License and Author
==================

Author:: Stathy Touloumis

CreatedBy:: Stathy Touloumis (<stathy@mesosphere.com>)

Copyright:: 2015, Mesosphere

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

