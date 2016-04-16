# VirtualBox Guest Additions

Ideally, the vagrant box image used by dcos-vagrant includes VirtualBox Guest Additions compatible with the latest versions of VirtualBox. It should "just work".

However, if they are out of date or incompatible with your installed version of VirtualBox you may want to install the [VBGuest Vagrant Plugin](https://github.com/dotless-de/vagrant-vbguest) to automatically install VirtualBox Guest Additions appropriate to your local VirtualBox version on each new VM after it is created.

## Install

```bash
vagrant plugin install vagrant-vbguest
```

This allows the pre-built vagrant box image to work on multiple (past and future) versions of VirtualBox.
