# Demo Java-Spring App

This demo app uses Java and Spring-Boot. It can be deployed as a native app or containerized with Docker. It is deployed using Marathon.

## Table of Contents

- [Containerized](#containerized)
- [Native](#native)
- [Load Balancer](#load-balancer)


## Containerized

Containerized Marathon apps will download the required Docker image from DockerHub (or a specified docker registry).

**Deploy**

```bash
dcos marathon app add examples/java-spring/java-spring-docker.json
```

**Access**

```bash
APP_ADDRESS=$(curl -s http://m1.dcos/marathon/v2/apps/java-spring-docker | \
  jq '.app.tasks[0].host + ":" + (.app.tasks[0].ports[0] | tostring)' -r)
curl http://${APP_ADDRESS}
```

**Scale**

Since the app is configured to be unique per node, one private agent node is required for each app instance.

```bash
dcos marathon app update java-spring-docker instances=3
```


## Native

Running a native java app requires that the application jar and the Java JRE be installed on the agent nodes. Use `DCOS_JAVA_ENABLED=true` when deploying the agent nodes to install both automatically (requires the JRE to be downloaded to `<repo>/build/jre-*-linux-x64.tgz`).

**Deploy**

```bash
dcos marathon app add examples/java-spring/java-spring.json
```

**Access**

```bash
APP_ADDRESS=$(curl -s http://m1.dcos/marathon/v2/apps/java-spring | \
  jq '.app.tasks[0].host + ":" + (.app.tasks[0].ports[0] | tostring)' -r)
curl http://${APP_ADDRESS}
```

**Scale**

Since the app is configured to be unique per node, one private agent node is required for each app instance.

```bash
dcos marathon app update java-spring instances=3
```


## Load Balancer

On production deployments of DC/OS, the private agent nodes are not usually externally accessible. So a load balancer (reverse proxy) is required in order to be able to access apps. One way to do that is with [Marathon-LB](https://github.com/mesosphere/marathon-lb), which can be installed from the [Mesosphere Universe package repository](https://github.com/mesosphere/universe).

**Deploy Marathon-LB**

```bash
dcos package install marathon-lb --yes
```

**Access Java-Spring App**

Hit the load balanced endpoint multiple times to be proxied to different agent nodes.


```bash
curl http://spring.acme.org/
```

==OR==

```bash
LB_PORT=$(curl -s http://m1.dcos/marathon/v2/apps/java-spring-docker | \
  jq '.app.ports[0]' -r)
curl http://p1.dcos:${LB_PORT}/
```
