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

**Solution**: Upgrade Ruby to >= 2.2. See [Appendix: Install Ruby](#install-ruby) for instructions.


## Package Install Failure

**Problem**: `dcos package install <package-name>` fails with the message `Unable to complete request due to downstream service [marathon] unavailability`.

**Solution**: SSH into the master nodes and restart the dcos-cosmos service.

```
vagrant ssh m1
service dcos-cosmos restart
```

This happens because Cosmos doesn't always pick up DNS changes that happen during bootstrap. Known bug in 1.6.1. Should be fixed in 1.7.0.
