# Oinker on Marathon on DC/OS

This example runs [Oinker-Go](https://github.com/mesosphere/oinker-go) on [Marathon](https://mesosphere.github.io/marathon/) on [DC/OS Vagrant](https://github.com/dcos/dcos-vagrant) with [Cassandra-Mesos](https://github.com/mesosphere/cassandra-mesos) and [Marathon-LB](https://github.com/mesosphere/marathon-lb).


## Install DC/OS

1. Follow the [dcos-vagrant setup](https://github.com/dcos/dcos-vagrant#setup) steps to configure your installation.
1. Use vagrant to deploy a cluster with 1 (large) private agent node and 1 (small) public agent node (requires 8.5 GB free memory):

    ```
    vagrant up m1 a1 p1 boot
    ```

1. Log into the DC/OS UI with a browser: <http://m1.dcos/>.
1. Install and configure the [DC/OS CLI](https://dcos.io/docs/latest/usage/cli/) by following the instructions in the DC/OS UI.
1. Log into DC/OS with the DC/OS CLI:

    ```
    vagrant auth login
    ```

    Follow the printed instructions to authenticate.

    If you were previously logged into a different cluster, you may have to logout first.


## Install Cassandra

1. Configure Cassandra with lower resource usage than default:

    ```
    cat >/tmp/cassandra.json <<EOF
    {
        "service": {
            "cpus": 0.1,
            "mem": 512,
            "heap": 256
        },
        "executor": {
            "cpus": 0.1,
            "mem": 512,
            "heap": 256
        },
        "nodes": {
            "cpus": 0.5,
            "mem": 2048,
            "disk": 4096,
            "heap": {
                "size": 1024,
                "new": 100
            },
            "count": 1,
            "seeds": 1
        },
        "task": {
            "cpus": 0.1,
            "mem": 128
        }
    }
    EOF
    ```
1. Install the cassandra package:

    ```
    dcos package install --options=/tmp/cassandra.json cassandra --yes
    ```
1. Wait for the Cassandra service to be running and healthy. Check the DC/OS Services UI: <http://m1.dcos/#/services/>.

    The Cassandra service should deploy 1 scheduler task and 1 cassandra node task on private DC/OS nodes.
    These can be seen on the service detail page.
    The service won't be marked as healthy or done deploying until both tasks are running and healthy.


## Install Marathon-LB

For Mesosphere Enterprise DC/OS, follow the instructions to [Install Marathon-LB on Mesosphere Enterprise DC/OS](enterprise-mlb.md).

For open DC/OS, use the following steps to configure and install Marathon-LB:

1. Configure marathon-lb with lower memory usage than default:

    ```
    cat >/tmp/marathon-lb.json <<EOF
    {
        "marathon-lb": {
            "mem": 256
        }
    }
    EOF
    ```
1. Install the marathon-lb package:

    ```
    dcos package install --options=/tmp/marathon-lb.json marathon-lb --yes
    ```
1. Wait for the Marathon-LB service to be running and healthy. Check the DC/OS Services UI: <http://m1.dcos/#/services/>.

    The Marathon-LB service should deploy 1 task on the public DC/OS node. This can be seen on the service detail page.


## Install Oinker

1. Create the Oinker app:

    ```
    dcos marathon app add examples/oinker/oinker.json
    ```
1. Wait for Marathon to deploy 3 app instances.

    ```
    dcos marathon app show oinker | jq -r '"\(.tasksHealthy)/\(.tasksRunning)/\(.instances)"'
    ```
1. Visit the load-balanced endpoint in a browser: <http://oinker.acme.org/>
