## mysqldump

This dockerizes a simple script I wrote in 2008 to perform a daily dump of
the MySQL databases in a Percona Galera cluster.

This Docker compose service definition will cause a dump to happen
at the default hour (3:30am in $TZ) from a server named xdb00 onto
the host directory /var/dvol/backup/mysql.

### Usage
Before running it, grant access to a mysql user thus:

    mysql> GRANT SELECT,RELOAD,SUPER,REPLICATION CLIENT ON *.* TO
      '$USER'@'10.%' IDENTIFIED BY '$PSWD';

Make sure the /var/dvol/backup/mysql directory exists, and that
your mysql-backup secret contains the $PSWD you've set:

    # docker secret create mysql-backup -
    user=bkp
    password=$PSWD

Optionally, add this role user to your Docker host ($UID can be overridden if
desired, in the service definition):

    useradd -u 210 -c "Mysql backups" -s /bin/bash mysqldump

Retention is set by a variable $KEEP_DAYS which defaults to 31: within
the directory you will find a subdirectory xdb00, and within that a
separate directory for each day of the month. If you set $KEEP_DAYS
to 7, it will keep a directory for each day of the week. Backups older
than $KEEP_DAYS will be automatically removed.

### Variables

| HOUR | cron-syntax backup hour (3) |
| KEEP_DAYS | days of snapshots to keep (31) |
| LOCK_FOR_BACKUP | true if using Percona, blank for MariaDB |
| MINUTE | cron-syntax minutes past hour (30) |
| SERVERS | servers to back up (dbhost) |
| TZ | time zone (US/Pacific) |

