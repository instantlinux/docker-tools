#! /bin/bash
echo [client] > /home/$USERNAME/.my.cnf
cat /var/run/secrets/mysql-backup >> /home/$USERNAME/.my.cnf

touch /var/log/mysqldump.log
chown $USERNAME /var/backup /var/log/mysqldump.log /home/$USERNAME/.my.cnf
echo "$MINUTE $HOUR * * *   $USERNAME  /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   >/etc/cron.d/mysql-backup

cron
tail -f /var/log/mysqldump.log
