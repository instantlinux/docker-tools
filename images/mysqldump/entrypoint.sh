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

[ -z "$COMPRESS" ] && COMPRESS=bzip2

cat <<EOF >/home/$USERNAME/.profile
export COMPRESS="$COMPRESS"
export COMPRESSLEVEL=$COMPRESSLEVEL
export COMPRESSOPTS="$COMPRESSOPTS"
export SKEW_SECONDS=$SKEW_SECONDS
EOF

touch $LOG
chown $USERNAME /var/backup $LOG $CNF /home/$USERNAME/.profile
chmod 400 $CNF
echo "$MINUTE $HOUR * * *   . /home/$USERNAME/.profile && \
   /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   | crontab -u $USERNAME -

crond
tail -f $LOG
