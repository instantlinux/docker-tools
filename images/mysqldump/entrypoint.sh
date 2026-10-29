#! /bin/sh
CNF=/home/$USERNAME/.my.cnf
LOG=/var/log/mysqldump.log
echo [client] > $CNF
cat /run/secrets/$DB_CREDS_SECRETNAME >> $CNF
[ $SKIP_SSL = true ] && echo "skip-ssl=true" >> $CNF
chmod 400 $CNF

[ -z "$COMPRESS" ] && COMPRESS=bzip2

echo "$MINUTE $HOUR * * * \
   /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   > /home/$USERNAME/crontab
touch $LOG && tail -0f $LOG &
exec supercronic /home/$USERNAME/crontab
