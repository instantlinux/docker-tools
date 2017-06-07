## mariadb-galera

MariaDB 10.2 with Galera clustering support, for deployment under
Swarm using Docker's named volumes for data persistence. This has a
robust bootstrap script intended to closely follow Galera's
documentation.

Current status: in development to handle edge cases upon cluster restart

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| CLUSTER_JOIN | | join address--usually not needed |
| CLUSTER_NAME | (required) | cluster name |
| CLUSTER_SIZE | 3 | expected number of nodes |
| DISCOVERY_SERVICE | | etcd host list, e.g. etcd1:2379,etcd2:2379 |
| REINSTALL_OK | | set to any value to enable reinstall over old volume |
| ROOT_PASSWORD_SECRET | mysql-root-password | name of secret for password |
| TTL | 10 | longevity of keys posted to etcd |
| TZ | US/Pacific | timezone |
| XTRABACKUP_PASSWORD | | password for SST transfers (deprecated) |
| XTRABACKUP_SECRET | xtradb-root-password | name of secret for password |

### Usage

Create a root password:
~~~
    PW=`uuidgen` ; echo $PW
    echo $PW | docker secret create mysql-root-password -
~~~
Set any local my.cnf values in files under a volume mount for
/etc/mysql/my.cnf.d.

### Networking

The container exposes ports 3306, 4567 and 4568 on the ingress network. An
internal network is needed for cluster-sync traffic and/or backups (use
xtrabackup, or the mysqldump container provided here). In order to enable
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
DB clustering under Docker Swarm is still in its infancy and I could
not find a clustering solution that would automatically restart
without problems (like split-brain, or just never coming up) upon a
simple "docker stack deploy ; docker stack rm ; docker stack deploy"
repeated test cycle. This is an attempt to address that problem, using
a minimal distro (tried Alpine Linux, wound up having to use debian
jessie-slim), with MariaDB (I like it better than MySQL / Percona
solutions, after a few years of running MariaDB and a decade+ of
running MySQL).

Galera is finicky upon restarts so this requires a robust script to ensure
proper conditions.

This container image is intended to be run in a 3-, 5-node, or larger
configuration.  It requires a stable etcd configuration for node
discovery and master election at restart.

### Credits

Thanks to ashraf-s9s of severalnines for the healthcheck script.
