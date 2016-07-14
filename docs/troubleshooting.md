# Troubleshooting

Common errors when bringing up the cluster, and their solutions.


## Provision Environment Support

**Problem**: `The following settings shouldn't exist: env`

**Solution**: [Upgrade Vagrant](https://www.vagrantup.com/downloads.html) to >= 1.8.1 (Ubuntu's package manager repos are out of date, install manually).


## Missing Installer Config

**Problem**: `Specified config file '/genconf/config.yaml' does not exist`

**Solution**: DC/OS >= 1.5 requires a yaml config file, not json (used by prior versions of DC/OS). Make sure the `DCOS_CONFIG_PATH` environment variable points to a file with the correct format for your DC/OS version before running vagrant:

```
export DCOS_CONFIG_PATH=etc/1_master-config-1.5.yaml
```


## Old Installer Config

**Problem**

```
Configuration generation (--genconf) requires the following errors to be fixed:
dcos_installer:: exhibitor_zk_hosts
dcos_installer:: master_list
```

**Solution**: DC/OS >= 1.6 requires a flattened yaml config file. Make sure the `DCOS_CONFIG_PATH` environment variable points to a file with the correct schema for your DC/OS version before running vagrant:

```
export DCOS_CONFIG_PATH=etc/config-1.6.yaml
```


## Missing VirtualBox Host-Only Network

**Problem**: `Could not find interface 'vboxnet0'`

```
$ vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
VBoxManage: error: The host network interface with the given name could not be found
VBoxManage: error: Details: code NS_ERROR_INVALID_ARG (0x80070057), component Host, interface IHost, callee nsISupports
VBoxManage: error: Context: "FindHostNetworkInterfaceByName(name.raw(), hif.asOutParam())" at line 218 of file     VBoxManageHostonly.cpp
VBoxManage: error: Could not find interface 'vboxnet0'
```

**Solution**: The `vboxnet0` host-only network must exist before it can be configured:

```
$ vboxmanage hostonlyif create
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interface 'vboxnet0' was successfully created
$ vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.65.1
```


## Old Ruby

**Problem**: One or more Vagrant plugins fail to install.

**Solution**: Upgrade Ruby to >= 2.2. See [Install Ruby](/docs/install-ruby.md) for instructions.


## Package Install Failure

**Problem**: `dcos package install <package-name>` fails with the message `Unable to complete request due to downstream service [marathon] unavailability`.

**Solution**: SSH into the master nodes and restart the dcos-cosmos service.

```
vagrant ssh m1
service dcos-cosmos restart
```

This happens because Cosmos doesn't always pick up DNS changes that happen during bootstrap. Known bug in 1.6.1. Should be fixed in 1.7.0.

## Too Many Open Files

**Problem**: `vagrant up` errors with `Too many open files - getcwd (Errno::EMFILE)`

**Solution**: Increase the file limit on the host

```
ulimit -n 1024
```

## Unable to login to your DC/OS cluster

**Problem**: Trying to login to http://m1.dcos/ fails with the message `Unable to login to your DC/OS cluster. Clusters must be connected to the internet.`

**Solution**: Ensure that you have installed the latest version of VirtualBox (5.0.20+).

## Plugin Install Fails on Vagrant 1.8.3

**Problem**: The following error is returned when attempting to `vagrant plugin install vagrant-hostmanager`

```
...
/usr/local/lib/ruby/site_ruby/2.1/rubygems/specification.rb:945:in `all=': undefined method `group_by' for nil:NilClass (NoMethodError)
...
```

**Solution**: Upgrade Vagrant to 1.8.4+ to fix an incompatibility with Ruby 2.3

## Vagrant up fails on Vagrant 1.8.4 with VirtualBox 5.1

**Problem**: The following error is returned when booting up a cluster via `vagrant up` using Vagrant
1.8.4 and VirtualBox 5.1.

```
No usable default provider could be found for your system.
...
```
This is a known behavior and should be fixed with Vagrant 1.8.5. See [mitchellh/vagrant#7411](https://github.com/mitchellh/vagrant/issues/7411) for details.

**Solution**: Using [VirtualBox 5.0](https://www.virtualbox.org/wiki/Download_Old_Builds_5_0) should resolve the incompatibility.
