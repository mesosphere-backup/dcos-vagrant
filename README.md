# DC/OS Vagrant

Quickly provision a [DC/OS](https://github.com/dcos/dcos) cluster on a local machine for development, testing, or demonstration.

Deploying DC/OS Vagrant involves creating a local cluster of VirtualBox VMs using the [dcos-vagrant-box](https://github.com/dcos/dcos-vagrant-box) base image and then installing [DC/OS](https://dcos.io/).

[![Build Status](https://jenkins.mesosphere.com/service/jenkins/buildStatus/icon?job=dcos-vagrant-test-e2e)](https://jenkins.mesosphere.com/service/jenkins/view/dcos-vagrant/job/dcos-vagrant-test-e2e/)

### Issue Tracking

- Issue tracking is in [DCOS JIRA](https://jira.mesosphere.com/projects/DCOS_VAGRANT/).
- Remember to make a DC/OS JIRA account and login so you can get update notifications!


# Quick Start

1. Install [Git](https://git-scm.com/downloads), [Vagrant](https://www.vagrantup.com/downloads.html), and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

1. Install vagrant-hostmanager plugin

    ```
    vagrant plugin install vagrant-hostmanager
    ```

1. Clone, Configure, and Deploy

    ```
    git clone https://github.com/dcos/dcos-vagrant
    cd dcos-vagrant
    cp VagrantConfig-1m-1a-1p.yaml VagrantConfig.yaml
    vagrant up
    ```

    When prompted for a password, provide your local machine user password (modifies `/etc/hosts`).

1. Access the GUI <http://m1.dcos/>

1. Install the DC/OS CLI

   ```
   ci/dcos-install-cli.sh
   ```

For more detailed instructions, see [Deploy](/docs/deploy.md) and [Configure](/docs/configure.md).


# DC/OS Versions

Official releases of DC/OS can be found at <http://dcos.io/releases/>

By default, DC/OS Vagrant uses the latest **stable** version of DC/OS.

To use a different **stable** or **early access** version, specify the version explicitly (must be in the [list of known releases](dcos-versions.yaml)):

```
export DCOS_VERSION=1.9.0-rc1
vagrant up
```

To use a bleeding edge **master**, **enterprise**, or **custom** build, download the installer yourself, place it under the dcos-vagrant directory, and configure DC/OS Vagrant to use it:

```
export DCOS_GENERATE_CONFIG_PATH=dcos_generate_config-1.9.0-dev.sh
export DCOS_CONFIG_PATH=etc/config-1.9.yaml
vagrant up
```


# DC/OS Vagrant Documentation

- [Deploy](/docs/deploy.md)
- [Configure](/docs/configure.md)
- [Upgrade](/docs/upgrade.md)
- [Examples](/examples)
- [Audience and Goals](/docs/audience-and-goals.md)
- [Network Topology](/docs/network-topology.md)
- [Alternate Install Methods](/docs/alternate-install-methods.md)
- [DC/OS Install Process](/docs/dcos-install-process.md)
- [Install Ruby](/docs/install-ruby.md)
- [Repo Structure](/docs/repo-structure.md)
- [Troubleshooting](/docs/troubleshooting.md)
- [VirtualBox Guest Additions](/docs/virtualbox-guest-additions.md)


# How Do I...?

- Learn More - https://dcos.io/
- Find the Docs - https://dcos.io/docs/
- Get Help - http://chat.dcos.io/
- Join the Discussion - https://groups.google.com/a/dcos.io/d/forum/users/
- Report a DC/OS Vagrant Issue - https://jira.mesosphere.com/projects/DCOS_VAGRANT/
- Report a DC/OS Issue - https://jira.mesosphere.com/projects/DCOS_OSS/
- Contribute - https://dcos.io/contribute/


# License

Copyright 2015-2017 Mesosphere, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this repository except in compliance with the License.

The contents of this repository are solely licensed under the terms described in the [LICENSE file](/LICENSE) included in this repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
