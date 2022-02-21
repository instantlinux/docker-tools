## mysqldump
[![](https://img.shields.io/docker/v/instantlinux/mysqldump?sort=date)](https://hub.docker.com/r/instantlinux/mysqldump/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/mysqldump?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/mysqldump "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/mysqldump/Dockerfile "dockerfile")

This dockerizes a simple script I wrote in 2008 to perform a daily dump of
the MySQL databases in a Percona Galera cluster. This image is based on
MariaDB 10.3.x client.

This Kubernetes or docker-compose service definition will cause a dump to happen
at the default hour (3:30am in $TZ) from a server named dbhost onto
a subdirectory "mysql" in volume "backup".

### Usage
Before running it, grant access to a mysql user thus:
~~~
    mysql> GRANT SELECT,RELOAD,SUPER,REPLICATION CLIENT ON *.* TO
      '$USER'@'10.%' IDENTIFIED BY '$PSWD';
~~~
Make sure the named volume "backup" exists, and that
your mysql-backup secret contains the $PSWD you've set:
~~~
    # docker volume create backup
    # docker secret create mysql-backup - <<EOT
    user=bkp
    password=$PSWD
    EOT
~~~
Optionally, add this role user to your Docker host:
~~~
    useradd -u 210 -c "Mysql backups" -s /bin/bash mysqldump
~~~
(Not recommended: an alternative user can be specified if you override
the entrypoint to invoke _adduser_, and define the USERNAME environment
variable.)

Retention is set by a variable $KEEP_DAYS which defaults to 31: within
the directory you will find a subdirectory dbhost, and within that a
separate directory for each day of the month. If you set $KEEP_DAYS
to 7, it will keep a directory for each day of the week. Backups older
than $KEEP_DAYS will be automatically removed.

Launch this docker image in kubernetes or docker-compose using one of the
files provided here. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/mysqldump/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/mysqldump/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make mysqldump
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| DB_CREDS_SECRET | mysql-backup-creds | Name of secret |
| HOUR | 3 |cron-syntax backup hour |
| KEEP_DAYS | 31 | days of snapshots to keep |
| LOCK_FOR_BACKUP | | true if using Percona, blank for MariaDB |
| MINUTE | 30 | cron-syntax minutes past hour |
| SERVERS | dbhost | servers (space-separated list) to back up |
| SKEW_SECONDS | 15 | wait between dumps |
| USERNAME | mysqldump | username to run as |
| TZ | UTC | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| mysql-backup-creds | Username/password for MySQL user |

An example to define credentials in Kubernetes:
```
apiVersion: v1
kind: Secret
metadata:
  name: mysql-backup-creds
type: Opaque
data:
  mysql-backup-creds: |
    password=yourmileagemayvary
    user=backupallthethings
```

### Notes

Dumps run in parallel in order to use available multi-core CPUs
(mainly for compression). You can limit the number of simultaneous
runs by changing the value of SKEW_SECONDS, so if your server has many
databases, increase this to prevent consuming excessive memory or CPU.

It's tested on MariaDB, so the LOCK_FOR_BACKUP parameter isn't really
supported unless someone submits a pull-request to make this work with
Percona again.

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-mariadb%2Fserver%2Fclient-blue.svg)](https://github.com/mariadb/server/tree/10.3/client "Code repo")
