Deploy DC/OS Vagrant
==================

- [Requirements](#requirements)
- [Setup](#setup)
- [Deploy](#deploy)
- [Install the CLI](#install-the-cli)
- [Example Deployments](#example-deployments)
- [Scale](#scale)
- [Destroy](#destroy)


# Requirements

## Hardware

**Minimum**:

- 9.5GB free memory (16GB system memory)

Most service packages *can* be installed on the Minimum cluster, **when individually configured to use minimal resources**, but not all at the same time.

## Operating System

Ideally, DC/OS Vagrant would work everywhere Vagrant and VirtualBox do, but each platform tends to require custom tweaks to the vagrant and guest OS configurations.

The following host OS's have been reported to work (regularly tested versions in bold):

- Mac OS X **10.10**, 10.11, 10.12
- Windows 7, **10**
- Ubuntu 14, 15, **16**
- Fedora 23
- Arch Linux

The default guest OS box from [dcos-vagrant-box](https://github.com/dcos/dcos-vagrant-box) uses CentOS 7.2.

## Software

- [Git](https://git-scm.com/) - clone repo
- [Vagrant](https://www.vagrantup.com/) (1.9.7 recommended) - virtualization orchestration
  - [Host Manager Plugin](https://github.com/smdahlen/vagrant-hostmanager) - manage /etc/hosts
  - (Optional) [VBGuest Plugin](https://github.com/dotless-de/vagrant-vbguest) - manage vbox guest additions
- [VirtualBox](https://www.virtualbox.org/) (5.1.24 recommended) - virtualization engine
- (Optional) [jq](https://stedolan.github.io/jq/) - json parser used by examples

**Vagrant Notes**:

Versions marked [PATCHED] have a patch included in dcos-vagrant to work around the issue.<br/>
Versions marked [INCOMPATIBLE] are incompatible with dcos-vagrant.

- [Vagrant 1.9.4 has a connection aborted without retry Windows bug](/docs/troubleshooting.md#connection-aborted-without-retry) [INCOMPATIBLE]
- [Vagrant 1.9.1 has a network interface detection bug](https://github.com/mitchellh/vagrant/issues/8115) [PATCHED]
- [Vagrant 1.8.7 has a problem with downloading boxes](https://github.com/mitchellh/vagrant/issues/7969) [INCOMPATIBLE]
- [Vagrant 1.8.6 has a network interface detection bug](/docs/troubleshooting.md#network-interface-configuration-failure) [PATCHED]
- [Vagrant 1.8.5 has an SSH key permissions bug](/docs/troubleshooting.md#ssh-authentication-failure) [INCOMPATIBLE]
- [Vagrant 1.8.4 and earlier are incompatible with VirtualBox 5.1](/docs/troubleshooting.md#no-usable-default-provider)
- Vagrant 1.8.3 and earlier are incompatible with Ubuntu 16

**VirtualBox Notes**:

- VirtualBox 5.0.18 and earlier are incompatible with Windows 10.

## Supported DC/OS Versions

Known versions: [dcos-versions.yaml](/dcos-versions.yaml)

For additional options, see [Specify DC/OS Version](/docs/configure.md#specify-dcos-version) or [Specify DC/OS Installer](/docs/configure.md#specify-dcos-installer).


# Setup

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

    On some versions of Mac OS X, installing vagrant plugins may require [installing a modern version of Ruby](/docs/install-ruby.md).

1. (Optional) [Specify DC/OS Version](/docs/configure.md#specify-dcos-version) or [Specify DC/OS Installer](/docs/configure.md#specify-dcos-installer)

1. Configure the DC/OS Machine Types

    Copy the example VagrantConfig file:

    ```bash
    cd <repo>
    cp VagrantConfig-1m-1a-1p.yaml VagrantConfig.yaml
    ```

    See [Configure DC/OS Vagrant](/docs/configure.md) for more details on customizing your cluster.

1. (Optional) Download/Update the VM Base Image

    By default, Vagrant should automatically download the latest VM Base Image (virtualbox box) when you run `vagrant up <machines>`, but downloading the image takes a while the first time. You may want to trigger the download or update manually.

    ```
    vagrant box add https://downloads.dcos.io/dcos-vagrant/metadata.json
    ```

    If you already have the latest version downloaded, the above command will fail.

    **Known Issue**: Vagrant's box downloader is [known to be slow](https://github.com/mitchellh/vagrant/issues/5319). If your download is super slow (100-300k/s range), then cancelling the download (Ctrl+C) and restarting it *sometimes* makes it download faster.

1. (Optional) Configure Authentication

    The cluster uses external OAuth by default, which will prompt for authentication through Google, Github, or Microsoft. The first user to log in becomes the superuser and must add additional users to allow multiple. It's also possible to [disable login](https://dcos.io/docs/1.8/administration/id-and-access-mgt/managing-authentication/#authentication-opt-out) in the installation config, if desired.

    When installing **Mesosphere Enterprise DC/OS** on DC/OS Vagrant, the cluster uses an internal user database by default, which will prompt for a username and password. If you're using the provided (1.7 or 1.8) installer config file then the superuser credentials are by default `admin`/`admin`. See [Managing users and groups](https://docs.mesosphere.com/1.8/administration/id-and-access-mgt/users-groups/) for more details about users and groups.

1. (Optional) Configure Other Options

    DC/OS Vagrant supports many other [configurable options via environment variables](/docs/configure.md#environment-options). Skip these for first time use.


# Deploy

By default, all machines in the selected configuration are deployed.

```bash
vagrant up
```

Many permutations of machines are possible. See [Example Deployments](#example-deployments) for more options.

Once the the machines are created and provisioned, DC/OS will be installed. Once complete, the web interface will be available at <http://m1.dcos/>.

See the [DC/OS Usage docs](https://dcos.io/docs/latest/usage/) for more information on how to use your new DC/OS cluster.


# Install the CLI

```bash
ci/dcos-install-cli.sh
```

For reference, see [DC/OS CLI](https://docs.io/latest/usage/cli/)


# Example Deployments

DC/OS Vagrant deployments consist of various permutations of several types of machines. Below are a few options to try.

See [Configure](/docs/configure.md) for more details about node types, cluster constraints, and resource constraints.

## Minimal Cluster

A minimal cluster supports the installation of a [minimally configured Cassandra, Marathon-LB, and Oinker example service](/examples/oinker).
Most default configuration service packages will fail to install, because they require more memory or more than one agent node, but most may be configured to use fewer resources.

```bash
cp VagrantConfig-1m-1a-1p.yaml VagrantConfig.yaml
vagrant up
```

By default, a minimal cluster requires 9.5GB free host memory.

## Multi-Master Cluster

Clusters must have an odd number of master nodes (usually 1, 3, or 5).

To deploy a cluster with three masters:

```bash
cp VagrantConfig-3m-1a-1p.yaml VagrantConfig.yaml
vagrant up
```

By default with this config, each master requires 1GB free host memory.

Note: Master nodes may not be added to a DC/OS cluster after initial install.

## Multi-Agent Cluster

To deploy a cluster three private agents:

```bash
cp VagrantConfig-1m-3a-1p.yaml VagrantConfig.yaml
vagrant up
```

Individual virtual machines may be configured with greater or fewer resources in `VagrantConfig.yaml`. This is most useful for public and private agent nodes that make their resources available for DC/OS services and jobs.

By default (using the example [VagrantConfig](/VagrantConfig.yaml.example)), each private agent machine requires 6GB free host memory, 5.5GB of which is made available to DC/OS. By default, each public agent machine requires 1.5GB free host memory, 1GB of which is made available to DC/OS.

Note: Public agents are most often used for load balancers, like Marathon-LB. Other services are deployed on private agents to provide a DMZ for security reasons (tho those reasons are moot for a local development cluster on a host-only network). Regardless, most service packages default to installing onto private agent nodes.

# Scale

DC/OS Vagrant allows for easy scaling up and down by adding and removing public or private agent nodes.

Note: DC/OS itself does not allow changing the number of master nodes after installation.

Adding more nodes to an existing cluster requires your VagrantConfig.yaml to have both new and old nodes configured.

## Add an Agent Node

To add a node, your `VagrantConfig.yaml` must have more agents specified than you currently have deployed.

Adding a node will not immediately change scheduled services, but may allow pending tasks to be scheduled using the newly available resources.

```
# Example initial cluster deploy
cp VagrantConfig-1m-3a-1p.yaml VagrantConfig.yaml
vagrant up m1 a1 p1 boot
# Add a private agent node
vagrant up a2
```

## Remove an Agent Node

Removing an agent node will cause all tasks running on that node to be rescheduled elsewhere, if resources allow.

```
# Example initial cluster deploy
cp VagrantConfig-1m-3a-1p.yaml VagrantConfig.yaml
vagrant up
# Remove a private agent node
vagrant destroy -f a3
```

# Shutting Down and Deleting Your Cluster

The normal Vagrant way to shut down VMs is `vagrant halt`, but if you use that method then the cluster won't come up again. For this reason, `vagrant halt` of master nodes has been disabled by dcos-vagrant. For more information, see [JIRA VAGRANT-7](https://jira.mesosphere.com/browse/DCOS_VAGRANT-7).

Instead, the recommended way to shut down a cluster is to destroy it (removing the the VMs and deleting their disks):

```
vagrant destroy -f
```

If you need to preserve the state of the cluster, use suspend/resume, which stores and restores memory state:

```
vagrant suspend
vagrant resume
```

Restoring after a significant amount of time may cause timeouts to expire almost instantly after resume, as the VM clocks are adjusted. DC/OS may not always automatically recover from this unnatural state.
