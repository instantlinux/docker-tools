## mysqldump
[![](https://images.microbadger.com/badges/version/instantlinux/mysqldump.svg)](https://microbadger.com/images/instantlinux/mysqldump "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mysqldump.svg)](https://microbadger.com/images/instantlinux/mysqldump "Image badge")

This dockerizes a simple script I wrote in 2008 to perform a daily dump of
the MySQL databases in a Percona Galera cluster. The image is compatible
with recent versions of MariaDB (10.x) and XtraDB (5.7.x).

This Docker compose service definition will cause a dump to happen
at the default hour (3:30am in $TZ) from a server named xdb00 onto
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
Optionally, add this role user to your Docker host ($UID can be overridden if
desired, in the service definition):
~~~
    useradd -u 210 -c "Mysql backups" -s /bin/bash mysqldump
~~~
Retention is set by a variable $KEEP_DAYS which defaults to 31: within
the directory you will find a subdirectory xdb00, and within that a
separate directory for each day of the month. If you set $KEEP_DAYS
to 7, it will keep a directory for each day of the week. Backups older
than $KEEP_DAYS will be automatically removed.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| HOUR | 3 |cron-syntax backup hour |
| KEEP_DAYS | 31 | days of snapshots to keep |
| LOCK_FOR_BACKUP | | true if using Percona, blank for MariaDB |
| MINUTE | 30 | cron-syntax minutes past hour |
| SERVERS | dbhost | servers to back up |
| TZ | US/Pacific | time zone |

