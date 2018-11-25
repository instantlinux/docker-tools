## mariadb-galera
[![](https://images.microbadger.com/badges/version/instantlinux/mariadb-galera.svg)](https://microbadger.com/images/instantlinux/mariadb-galera "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mariadb-galera.svg)](https://microbadger.com/images/instantlinux/mariadb-galera "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mariadb-galera.svg)](https://microbadger.com/images/instantlinux/mariadb-galera "Commit badge")

MariaDB 10.3 with automatic cluster generation under kubernetes / swarm using named volumes for data persistence. This has robust bootstrap logic based on MariaDB / Galera documentation for automated cluster create / join operations.

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
| SST_PASSWORD | | password for SST transfers (don't use this, use secret) |
| SST_AUTH_SECRET | sst-auth-password | name of secret for password |

### Usage

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
Do the same for an sst-auth-password.

Set any local my.cnf values in files under a volume mount for
/etc/mysql/my.cnf.d (mapped as $ADMIN_PATH/mariadb/etc/).

### Networking

The container exposes ports 3306, 4567 and 4568 on the ingress network. An
internal network is needed for cluster-sync traffic and/or backups (use
mariabackup, or the mysqldump container provided here). In order to enable
connections directly to each cluster member for troubleshooting, if you're
running a recent version of Docker you can override the ingress
load-balancer thus:

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
You may want a separate load-balancer for serving your published port.

### Logging

Logs are sent to stdout / stderr with one exception: the slow query
log. Add a volume mount of /var/log/mysql if you want to preserve
that log.

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
discovery and master election at restart.

### Setting up etcd

See the k8s/Makefile for a _make etcd_ to start	etcd using helm under kubernetes. A docker-compose service definition is available at [docker-tools/services/etcd](https://github.com/instantlinux/docker-tools/tree/master/services/etcd). Instructions for using the free discovery.etc.io bootstrap service are given there.

### Credits

Thanks to ashraf-s9s of severalnines for the healthcheck script.

[![](https://images.microbadger.com/badges/license/instantlinux/mariadb-galera.svg)](https://microbadger.com/images/instantlinux/mariadb-galera "License badge"
)