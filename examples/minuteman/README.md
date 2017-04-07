# Using Minuteman with Marathon on DC/OS

This example uses Minuteman on [Marathon](https://mesosphere.github.io/marathon/) on [DC/OS Vagrant](https://github.com/dcos/dcos-vagrant) with an example application [Helloworld](https://github.com/mesosphere/helloworld).

Minuteman, in this example will route the VIP `1.2.3.4:5000`. Although this is not an IP that actually exists in the cluster, if you try to make a TCP connection from any host in the cluster to this IP, it'll automatically be connected to the backend application.

The backend application we're using in our example is [Helloworld](https://github.com/mesosphere/helloworld). It has two endpoints, `/`, and `/stream`. `/` outputs an example string, as well as the machine, and port that instance of the application is running on. The stream endpoint makes a long-lived TCP, streaming connection.

Remember, the Minuteman VIPs are only accessible from other machines running Minuteman, and not the cluster as a whole!

## Install DC/OS

1. Follow the [dcos-vagrant setup](https://github.com/dcos/dcos-vagrant#setup) steps to configure your installation.

1. Use vagrant to deploy a cluster with 1 private agent node and 1 public agent node (requires 9.5GB free memory):

    ```
    cp VagrantConfig-1m-1a-1p.yaml VagrantConfig.yaml
    vagrant up
    ```
1. Wait for DC/OS to come up. Check the dashboard: <http://m1.dcos/>.

1. Install the [DC/OS CLI](https://dcos.io/docs/latest/usage/cli/)

    ```
    curl https://raw.githubusercontent.com/dcos/dcos-vagrant/master/ci/dcos-install-cli.sh | bash
    ```



## Install Example App

1. Create the example app:

    ```
    dcos marathon app add examples/minuteman/minuteman.json
    ```
1. Wait for Marathon to deploy 3 app instances.

    ```
    dcos marathon app show minuteman | jq -r '"\(.tasksHealthy)/\(.tasksRunning)/\(.instances)"'
    ```
1. Visit the load balanced endpoint from any of the master or agent nodes in the cluster.
You can do this by running the following commands:

	```
	vagrant ssh a1
	curl http://1.2.3.4:5000
	```
	If you invoke multiple curl requests, you should see different backends responding.


## Enable Minuteman on Your own App
Add a label in the format `vip_PORT${IDX}` -> `tcp://1.2.3.4:5000`. Where, `1.2.3.4:5000` is the VIP. `${IDX}` should be replaced by the index for the port, beginning from 0 in the resource allocations.
