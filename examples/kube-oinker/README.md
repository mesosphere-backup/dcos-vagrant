# Oinker on Kubernetes on DCOS

This example runs [Oinker-Go](https://github.com/mesosphere/oinker-go) on [Kubernete-Mesos](https://github.com/mesosphere/kubernetes-mesos) on [DCOS-Vagrant](https://github.com/mesosphere/dcos-vagrant) with [Cassandra-Mesos](https://github.com/mesosphere/cassandra-mesos).


## Install DCOS

1. Follow the [dcos-vagrant setup](https://github.com/mesosphere/dcos-vagrant#setup) steps to configure your installation.
1. Use vagrant to deploy a cluster with 4 agent nodes (requires 10GB free memory):

    ```
    vagrant up m1 a1 a2 a3 a4 boot
    ```
1. Wait for DCOS to come up. Check the dashboard: <http://m1.dcos/>.
1. Install the [dcos-cli](https://github.com/mesosphere/dcos-cli) by following the instructions on the DCOS Dashboard


## Install Cassandra

1. Configure Cassandra with lower memory usage than default:

    ```
    cat >/tmp/cassandra.json <<EOF
    {
      "cassandra": {
        "framework": {
          "mem": 512
        },
        "resources": {
          "mem": 128
        }
      }
    }
    EOF
    ```
1. Install cassandra:

    ```
    dcos package install --options=/tmp/cassandra.json cassandra --yes
    ```
1. Wait for the cassandra framework to deploy 3 executors and 3 servers (takes 5m+). Check the Mesos UI: <http://m1.dcos/mesos>.

## Add Multiverse Package Repository

Kubernetes and etcd are in the Multiverse repo. So the Multiverse must be added to the dcos-cli config.

See the [dcos-cli docs](../../docs.dcos-cli.md#multiverse) on how to add the multiverse repo.

## Install etcd

1. Configure etcd with lower memory usage than default:

    ```
    cat >/tmp/etcd.json <<EOF
    {
      "etcd": {
        "mem-limit": 128,
        "disk-limit": 256
      }
    }
    EOF
    ```
1. Install etcd:

    ```
    dcos package install --options=/tmp/etcd.json etcd --yes
    ```
1. Wait for the etcd framework to deploy 3 servers. Check the Mesos UI: <http://m1.dcos/mesos>.


## Install Kubernetes

1. Configure Kubernetes with lower memory usage than default:

    ```
    cat >/tmp/kubernetes.json <<EOF
    {
      "kubernetes": {
        "mem": 256,
        "etcd-mesos-framework-name": "etcd"
      }
    }
    EOF
    ```
1. Install Kubernetes:

    ```
    dcos package install --options=/tmp/etcd.json etcd --yes
    ```
1. Wait for the Kubernetes framework to deploy kube-dns and kube-ui. Check the Mesos UI: <http://m1.dcos/mesos>.


## Install Oinker

1. Create the Oinker replication controller and service:

    ```
    dcos kubectl create -f oinker.yaml
    ```
1. Wait for Kubernetes to deploy 3 pod instances. 

    ```
    dcos kubectl get pod -l=app=oinker
    ```
1. Find the oinker endpoint:

    ```
    dcos kubectl get endpoints -l=app=oinker
    ```

## TODO

1. Multiple oinker instances with a load balancer in front (e.g. [service-loadbalancer](https://github.com/kubernetes/contrib/tree/master/service-loadbalancer)) - requires more/larger nodes
