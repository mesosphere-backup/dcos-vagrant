# dcos-vagrant for Portworx
[Portworx](https://docs.portworx.com) highly availabile persistent data fabric for containers requires agents to 
provide additional local storage, to create the global storage pool.

This `portworx` examples directory allows test driving Portworx within a vagrant/vbox environment.

Please use these config files to startup a `portworx-ready` dcos-vagrant cluster.

This environment has been qualified against:
* server with 16GB physical memory
* vagrant version 2.0.2
* VirtualBox 5.1.28

Portworx can then be installed by following the [DCOS installation docs at docs.portworx.com](https://docs.portworx.com/scheduler/mesosphere-dcos/install.html)

When deploying Portworx from Universe for this `vagrant` cluster, make the following changes 
* Check the boxes to enable `etcd` and `lighthouse`
* Use `-d enp0s8 -m enp0s8` as [portworx options](https://docs.portworx.com/scheduler/mesosphere-dcos/install.html#portworx-options)
* Instead of the default values, specify `256` for the memory size of `etcd`, `influxdb` and `lighthouse`. 

After deploying, the DCOS GUI can be reachable by port 8080 on the local host machine.
