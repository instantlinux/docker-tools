## mariadb-galera
[![](https://img.shields.io/docker/v/instantlinux/mariadb-galera?sort=date)](https://hub.docker.com/r/instantlinux/mariadb-galera/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/mariadb-galera?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/mariadb-galera "Image badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/mariadb-galera/Dockerfile "dockerfile")

MariaDB 10.4 with automatic cluster generation under kubernetes / swarm using named volumes for data persistence. This has robust bootstrap logic based on MariaDB / Galera documentation for automated cluster create / join operations.

### Usage - kubernetes

Define the following dependencies before launching the cluster: passwords for root and SST, network load balancer, and a dedicated etcd key-value store. Here's how:

Create a random root password:
```
SECRET=mysql-root-password
PW=$(uuidgen | base64)
cat >/dev/shm/new.yaml <<EOT
---
apiVersion: v1
data:
  $SECRET: $PW
kind: Secret
metadata:
  name: $SECRET
  namespace: \$K8S_NAMESPACE
type: Opaque
EOT
sekret enc /dev/shm/new.yaml >secrets/$SECRET
rm /dev/shm/new.yaml
```
You can use a tool like [sops](https://github.com/mozilla/sops) or [sekret](https://github.com/nownabe/sekret) to generate the secrets file. Do the same for an sst-auth-password.

Set any local my.cnf values in files under a volume mount for
/etc/mysql/my.cnf.d (mapped as $ADMIN_PATH/mariadb/etc/). Use
a ConfigMap when running under Kubernetes (example is included).

### Networking

The container exposes ports 3306, 4444, 4567 and 4568 on the ingress network. An
internal network is needed for cluster-sync traffic and/or backups (use
mariabackup, or the mysqldump container provided here). In order to enable
connections directly to each cluster member for write-safe access or
troubleshooting, if you're running a recent version of Docker you can override
its ingress load-balancer thus:

~~~
    version: "3.2"
    services:
      db:
        ...
        ports:
        - target: 3306
          published: <port>
          protocol: tcp
          mode: host
~~~
You almost definitely want a separate load-balancer for serving your published port.
This method is defined and documented here in [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/mariadb-galera/kubernetes.yaml).

### DNS names and read/write

With MariaDB technology, write performance is limited to I/O throughput of the slowest single node in the cluster. Read performance can be scaled across the full cluster and is limited only by network capacity.

If you set up a cluster and spread database write traffic across all nodes, performance will be worse than with a single cluster because of issues described in [multi-master conflicts](http://galeracluster.com/documentation-webpages/dealingwithmultimasterconflicts.html). Your logs will have messages like these:
```
WSREP: MDL conflict db=jira7 table=rundetails ticket=6 solved by abort
```
and the cluster won't provide stable performance. To make this long story short, here are the steps to take:

* Allocate two static IP addresses on your LAN
* Define a primary and read-only DNS name, for example db.mysite.com and db-ro.mysite.com and add address A records for the two IPs
* Set up an haproxy (or other) load balancer for the primary IP address, with one cluster node configured to serve traffic and the others defined as backup
* Bind the built-in Docker or Kubernetes service to all the cluster members

For Docker Swarm users, this exercise is left to the reader. For Kubernetes, the [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/mariadb-galera/kubernetes.yaml) and [Makefile](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile) provided here will automate these steps once you've set up the two DNS entries.

### Logging

Logs are sent to stdout / stderr with one exception: the slow query
log. Add a volume mount of /var/log/mysql if you want to preserve
that log.

### Setting up etcd

See the [k8s/Makefile](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile) for a _make etcd_ to start etcd under kubernetes. A docker-compose service definition is available at [docker-tools/services/etcd](https://github.com/instantlinux/docker-tools/tree/main/services/etcd). Instructions for using the free discovery.etc.io bootstrap service are given there.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/mariadb-galera/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/mariadb-galera/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
# This make target is defined in Makefile.instances
make db00
~~~

### Usage - swarm

This was originally developed under docker Swarm. A [docker-compose](https://github.com/instantlinux/docker-tools/blob/main/images/mariadb-galera/docker.compose) file is a legacy of that original work. Before stack-deploying it, invoke _docker secret create_ to generate the two secrets _mysql-root-password_ and _sst-auth-password-, and define an ADMIN_PATH environment variable pointing to your my.cnf (it has to be in the same location on each docker node).

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| CLUSTER_JOIN | | join address--usually not needed |
| CLUSTER_NAME | cluster01 | cluster name |
| CLUSTER_SIZE | 3 | expected number of nodes |
| DISCOVERY_SERVICE | etcd:2379 | etcd host list, e.g. etcd1:2379,etcd2:2379 |
| REINSTALL_OK | | set to any value to enable reinstall over old volume |
| ROOT_PASSWORD_SECRET | mysql-root-password | name of secret for password |
| TTL | 10 | longevity (in seconds) of keys posted to etcd |
| TZ | UTC | timezone |
| SST_AUTH_SECRET | sst-auth-password | name of secret for password |

### Notes

When creating this image (in early 2017), DB clustering under Docker
Swarm was still in its infancy and I could not find a clustering
solution that would automatically restart without problems (like
split-brain, or just never coming up) upon a simple "docker stack
deploy ; docker stack rm ; docker stack deploy" repeated test
cycle. This addresses that problem, using a minimal distro (tried
Alpine Linux, wound up having to use debian). I like MariaDB better
than MySQL / Percona solutions, after a few years of running MariaDB
and a decade+ of running MySQL. A couple years later, there's still no
better alternative.

Galera is finicky upon restarts so it requires a fair amount of logic
to handle edge cases.

This container image is intended to be run in a 3-, 5-node, or larger
configuration.  It requires a stable etcd configuration for node
discovery and master election at restart. A single instance can
be invoked without HA resources using kubernetes-single.yaml.

### Credits

Thanks to ashraf-s9s of severalnines for the healthcheck script.

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-mariadb%2Fserver-blue)](https://github.com/MariaDB/server "Code repo")