# DC/OS Installation

The DC/OS installation is multi-stage with many moving parts.

## High Level Stages

1. Node machines are created and provisioned (master, agent-private, agent-public)
    1. Nodes are given IPs and added to a shared network
    1. SSH keys are updated
    1. SSL certificate authorities are updated
    1. Docker is configured to allow insecure registries (if configured)
1. Boot machine is created and provisioned
    1. Bootstrap Exhibitor (Zookeeper) is started
    1. Nginx is started to host generated node config artifacts
    1. Private Docker registry is started (if configured)
    1. Java runtime is copied from host and installed (if configured)
    1. DC/OS release (`dcos_generate_config.sh`) is copied from host
1. DC/OS pre-install
    1. DC/OS release config (`config.yaml` & `ip-detect`) is generated from list of active nodes
    1. DC/OS node config artifacts (`dcos_install.sh` & tarballs) are generated from the release and release config
1. DC/OS install
    1. Node config artifacts are distributed to the nodes and installed (based on node type)
    1. DC/OS systemd services are started on the nodes
1. DC/OS post-install
    1. Exhibitor starts, brings up Zookeeper
    1. Mesos Master starts up and registers with Zookeeper
    1. Mesos DNS detects Mesos Master using Zookeeper and initializes `leader.mesos`
    1. Root Marathon detects `leader.mesos` and starts up
        1. Root Marathon registers with the leading Mesos Master
    1. AdminRouter (nginx) detects `leader.mesos` starts up
        1. DC/OS, Mesos, Marathon, and Exhibitor UIs become externally accessible
    1. Mesos Slaves detect `leader.mesos` and start up
        1. Mesos Slaves register with the leading Mesos Master
        1. DC/OS Nodes become visible in the DC/OS UI

## System Logs

Ideally deployment and installation failures will be visible in the vagrant output, but sometimes failures occur in the background. This is especially true for systemd components that come up concurrently and wait for dependencies to come up.

To interrogate the system, it's possible to ssh into the machines using `vagrant ssh <machine>` and view the logs of all system components with `joutnalctl -f`.