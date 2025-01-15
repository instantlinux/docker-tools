#! /bin/sh
if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

CNF=/home/$USERNAME/.my.cnf
LOG=/var/log/mysqldump.log
echo [client] > $CNF
cat /run/secrets/$DB_CREDS_SECRETNAME >> $CNF
[ $SKIP_SSL = true ] && echo "skip-ssl=true" >> $CNF

touch $LOG
chown $USERNAME /var/backup $LOG $CNF
chmod 400 $CNF
echo "$MINUTE $HOUR * * *   /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   | crontab -u $USERNAME -

crond
tail -f $LOG
