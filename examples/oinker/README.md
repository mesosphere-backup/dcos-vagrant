# Oinker on Marathon on DC/OS

This example runs [Oinker-Go](https://github.com/mesosphere/oinker-go) on [Marathon](https://mesosphere.github.io/marathon/) on [DC/OS Vagrant](https://github.com/dcos/dcos-vagrant) with [Cassandra-Mesos](https://github.com/mesosphere/cassandra-mesos) and [Marathon-LB](https://github.com/mesosphere/marathon-lb).


## Install DC/OS

1. Follow the [dcos-vagrant setup](https://github.com/dcos/dcos-vagrant#setup) steps to configure your installation.
1. Use vagrant to deploy a cluster with 3 private agent nodes and 1 public agent node (requires 10GB free memory):

    ```
    vagrant up m1 a1 a2 a3 p1 boot
    ```
1. Wait for DC/OS to come up. Check the dashboard: <http://m1.dcos/>.
1. Install the [DC/OS CLI](https://dcos.io/docs/latest/usage/cli/) by following the instructions on the DC/OS Dashboard


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
1. Install cassandra:

    ```
    dcos package install --options=/tmp/cassandra.json cassandra --yes
    ```
1. Wait for the cassandra framework to deploy 3 executors and 3 servers (takes 5m+). Check the Mesos UI: <http://m1.dcos/mesos>.


## Install Marathon-LB

For Mesosphere Enterprise DC/OS, reference [the documentation for securely installing Marathon-LB](https://docs.mesosphere.com/1.8/usage/service-discovery/marathon-lb/usage/). Make sure to specify 256 MB memory when configuring Marathon-LB.

For vanilla DC/OS, use the following steps to configure and install Marathon-LB:

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
1. Install marathon-lb:

    ```
    dcos package install --options=/tmp/marathon-lb.json marathon-lb --yes
    ```
1. Wait for the marathon-lb framework to be running and healthy. Check the DC/OS Services UI: <http://m1.dcos/#/services/>.


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
