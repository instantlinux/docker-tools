#!/bin/sh
# $Id: backup_mysql_each.sh 183 2011-07-18 15:05:00Z richb $
#
# Created 4/2013 by rbraun
#
# This will keep daily dumps of each production database as separate files in
# subdirectories of /var/backup, by hostname and day of week.

# Parameters:
#  $1    Number of days' worth of backups to keep
#  $2-$  Hostnames (with optional port number if not 3306)

USER=bkp
LOG=/var/log/mysqldump.log
MYSQL=/usr/bin/mariadb
MYSQLDUMP=/usr/bin/mariadb-dump

log_entry () {
 IL_PRIORITY=$1
 IL_MSG=$2

 echo `date +"%h %d %H:%M:%S"` $IL_PRIORITY "$IL_MSG" >> $LOG
 return 0
}

log_entry info START

[ -z "$LOCK_FOR_BACKUP" ] || OPT_LOCK_FOR_BACKUP=--lock-for-backup

# Grants required for bkp user:
# GRANT SELECT,RELOAD,SUPER,REPLICATION CLIENT ON *.* TO '$USER'@'192.168.%' IDENTIFIED BY '$PSWD';

DUMPOPTS="--force --skip-opt --quick --single-transaction \
 $OPT_LOCK_FOR_BACKUP --add-drop-table --set-charset --create-options \
 --no-autocommit --extended-insert --routines"
SCHEMA_DUMP_OPTS=" --force --no-data --triggers --events --routines" 
DBNAME_QUERY="SELECT schema_name FROM information_schema.schemata \
 WHERE schema_name NOT IN ('sys','information_schema','performance_schema')"

DESTDIR=/var/backup/mysql
COMPRESS="bzip2 -f"
COMPRESS_EXT="bz2"
OLD_EXT="gz"
[ "$SKEW_SECONDS" = "" ] && SKEW_SECONDS=15

if [ "$#" -eq "0" ]; then
    echo "Usage: backup_mysql_all <days to keep> <list: instances>"
    exit
fi

KEEP_DAYS=$1
shift;

# Dumps will be kept in directories named as day of week or
# day of month if 31 or less; else combine month+day if longer

if [ $KEEP_DAYS == 7 ]; then
 DAY=`date +%a`
elif [ $KEEP_DAYS -le 31 ]; then
 DAY=`date +%d`
else
 DAY=`date +%m%d`
fi

for SERVER in $@
do
    HOST=$(echo $SERVER | cut -d: -f 1)
    PORT=$(echo $SERVER: | cut -d: -f 2)
    [ -z "$PORT" ] && PORT=3306
    OPTS="-u $USER -h $HOST -P $PORT"
    [ -d $DESTDIR/$SERVER/$DAY ] || mkdir -p -m 2750 $DESTDIR/$SERVER/$DAY
    # Delete any lingering files that are over KEEP_DAYS old:
    /usr/bin/find $DESTDIR/$SERVER/* -type f -mtime +$KEEP_DAYS -exec rm {} \; 2>&1 > /dev/null
    DBNAMES=`$MYSQL $OPTS -se "$DBNAME_QUERY"`
    STATFILE=$DESTDIR/$SERVER/mysqldump-status.txt
    # Grants
    $MYSQLDUMP $OPTS --system=users >$DESTDIR/$SERVER/$DAY/allgrants.sql

    for DBNAME in $DBNAMES; do
      # Schema only
      # Delete any lingering files from a previous run
      rm -f $DESTDIR/$SERVER/$DAY/$DBNAME-schema.sql.$OLD_EXT \
            $DESTDIR/$SERVER/$DAY/$DBNAME-schema.sql
      SCHEMA_TARGET=$DESTDIR/$SERVER/$DAY/$DBNAME-schema.sql
      ( $MYSQLDUMP $OPTS $SCHEMA_DUMP_OPTS \
           --databases $DBNAME >$SCHEMA_TARGET && \
        $COMPRESS $SCHEMA_TARGET & )

      # Data
      # Delete any lingering files from a previous run
      rm -f $DESTDIR/$SERVER/$DAY/$DBNAME-backup.sql.$OLD_EXT \
            $DESTDIR/$SERVER/$DAY/$DBNAME-backup.sql
      BACKUP_TARGET=$DESTDIR/$SERVER/$DAY/$DBNAME-backup.sql

      log_entry info " -- starting dump to $BACKUP_TARGET"
      ( $MYSQLDUMP $OPTS $DUMPOPTS --databases $DBNAME >$BACKUP_TARGET && \
        nice $COMPRESS $BACKUP_TARGET && \
        echo "`date -R` dumped $DBNAME" > $STATFILE & )
      sleep $SKEW_SECONDS
    done
done

log_entry info FINISHED
exit 0
