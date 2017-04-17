#! /bin/bash
touch /var/log/mysqldump.log /home/$USERNAME/.my.cnf
chown $USERNAME /var/backup /var/log/mysqldump.log /home/$USERNAME/.my.cnf
echo "$MINUTE $HOUR * * *   $USERNAME  /usr/local/bin/mysql-backup.sh $KEEP_DAYS $SERVERS" \
   >/etc/cron.d/mysql-backup

# TODO: generate .my.cnf from docker secrets
# cp /var/run/secrets/mysqldump-client /home/$USERNAME/.my.cnf

cron
tail -f /var/log/mysqldump.log
