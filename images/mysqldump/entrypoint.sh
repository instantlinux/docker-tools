#! /bin/sh
CNF=/home/$USERNAME/.my.cnf
LOG=/var/log/mysqldump.log
echo [client] > $CNF
cat /run/secrets/mysql-backup >> $CNF

touch $LOG
chown $USERNAME /var/backup $LOG $CNF
chmod 400 $CNF
echo "$MINUTE $HOUR * * *   /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   | crontab -u $USERNAME -

crond
tail -f $LOG
