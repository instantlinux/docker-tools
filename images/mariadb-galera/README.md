## mariadb-galera

MariaDB 10.2 with Galera clustering support, for deployment under Swarm
using Docker's named volumes for data persistence.

Current status: in development; still needs improvements in the
entrypoint bootstrap script to ensure all defined nodes wait long
enough for each other to start up and elect the most-current instance
for synchronization.  Indeed, bash is the wrong language for this
work: this script originates from Percona but needs to be thrown out
and started over in python. That said, this version will bring up a
cluster most of the time without fiddling with the compose file--an
improvement over what else is out there circa May 2017.

### Variables

|  CLUSTER_NAME | cluster name |
|  DISCOVERY_SERVICE | etcd host list, e.g. etcd1:2379,etcd2:2379 |
|  TZ | timezone (US/Pacific) |

### Usage

Create a root password:

   PW=`uuidgen` ; echo $PW
   echo $PW | docker secret create mysql-root-password -

Set any local my.cnf values in files under a volume mount for
/etc/mysql/my.cnf.d.

### Networking

The container exposes ports 3306, 4567 and 4568 on the ingress network. An
internal network is needed for cluster-sync traffic and/or backups (use
xtrabackup, or the mysqldump container provided here). In order to enable
connections directly to each cluster member for troubleshooting, if you're
running a recent version of Docker you can override the ingress
load-balancer thus:

    version: "3.2"
    services:
      db:
        ...
	ports:
	- target: 3306
	  published: <port>
	  protocol: tcp
	  mode: host

You'll need a separate load-balancer for serving your published port.

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
jessie-slim), using MariaDB (I like it better than MySQL / Percona
solutions, after a few years of running MariaDB and a decade+ of
running MySQL).

Galera is finicky upon restarts so this requires a robust script to ensure
proper conditions.

This container image is intended to be run in a 3-, 5-node, or larger configuration.
It requires a stable etcd configuration for node discovery and master election at
restart.

### Credits

Thanks to ashraf-s9s of severalnines for the healthcheck and etcd scripts.
