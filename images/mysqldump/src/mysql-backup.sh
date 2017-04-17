#!/bin/bash
# $Id: backup_mysql_each.sh 183 2011-07-18 15:05:00Z richb $
#
# Created 4/2013 by rbraun
#
# This will keep daily dumps of each production database as separate files in
# subdirectories of /var/backup, by hostname and day of week.

# Parameters:
#  $1    Number of days' worth of backups to keep
#  $2-$  Hostnames

USER=bkp
LOG=/var/log/mysqldump.log
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

log_entry () {
 IL_PRIORITY=$1
 IL_MSG=$2

 echo `date +"%h %d %H:%M:%S"` $IL_PRIORITY "$IL_MSG" >> $LOG
 return 0
}

log_entry info START

# Grants required for bkp user:
# GRANT SELECT,RELOAD,SUPER,REPLICATION CLIENT ON *.* TO '$USER'@'192.168.%' IDENTIFIED BY '$PSWD';

DUMPOPTS="--flush-logs --force -R --skip-opt --quick --single-transaction \
 --lock-for-backup --add-drop-table --set-charset --create-options \
 --no-autocommit --extended-insert --routines"
SCHEMA_DUMP_OPTS=" --flush-logs --force --no-data -R --triggers --events --routines" 
DBNAME_QUERY="SELECT schema_name FROM information_schema.schemata \
 WHERE schema_name NOT IN ('sys','information_schema','performance_schema')"

DESTDIR=/var/backup/
COMPRESS="bzip2 -f"
COMPRESS_EXT="bz2"
OLD_EXT="gz"

if [ "$#" -eq "0" ]; then
    echo "Usage: backup_mysql_all <days to keep> <list: instances>"
    exit
fi

KEEP_DAYS=$1
shift;

# Dumps will be kept in directories named as day of week or
# day of month if 31 or less; else combine month+day if longer

if [ $KEEP_DAYS == 7 ]
then
 DAY=`date +%a`
elif [ $KEEP_DAYS -le 31 ]
then
 DAY=`date +%d`
else
 DAY=`date +%m%d`
fi

for HOST in $@
do
    [ -d $DESTDIR/$HOST/$DAY ] || mkdir -p -m 2750 $DESTDIR/$HOST/$DAY
 # Delete any lingering files that are over KEEP_DAYS old:
    /usr/bin/find $DESTDIR/$HOST/* -type f -mtime +$KEEP_DAYS -exec rm {} \; 2>&1 > /dev/null
    DBNAMES=`$MYSQL -h $HOST -se "$DBNAME_QUERY"`
    for DBNAME in $DBNAMES; do
      # Schema only
      # Delete any lingering files from a previous incarnation (or incantation) of this script, compressed or otherwise:
      rm -f $DESTDIR/$HOST/$DAY/$DBNAME-schema.sql.$OLD_EXT
      rm -f $DESTDIR/$HOST/$DAY/$DBNAME-schema.sql
      SCHEMA_TARGET=$DESTDIR/$HOST/$DAY/$DBNAME-schema.sql
      ( $MYSQLDUMP -u $USER $SCHEMA_DUMP_OPTS -h $HOST --databases $DBNAME >$SCHEMA_TARGET && $COMPRESS $SCHEMA_TARGET & )

      # Data
      # Delete any lingering files from a previous incarnation (or incantation) of this script, compressed or otherwise:
      rm -f $DESTDIR/$HOST/$DAY/$DBNAME-backup.sql.$OLD_EXT
      rm -f $DESTDIR/$HOST/$DAY/$DBNAME-backup.sql
      BACKUP_TARGET=$DESTDIR/$HOST/$DAY/$DBNAME-backup.sql

      log_entry info " -- starting dump to $BACKUP_TARGET"
      ( $MYSQLDUMP -u $USER $DUMPOPTS -h $HOST --databases $DBNAME >$BACKUP_TARGET && $COMPRESS $BACKUP_TARGET & )
    done
done

log_entry info FINISHED
exit 0
