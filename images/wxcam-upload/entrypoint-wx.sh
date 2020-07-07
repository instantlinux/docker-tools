#!/bin/bash -e

if [ -e /run/secrets/$WXUSER_PASSWORD_SECRET ]; then
  adduser -u $WXUSER_UID -s /bin/sh -g "ftp user" -D $WXUSER_NAME
  echo "$WXUSER_NAME:$(cat /run/secrets/$WXUSER_PASSWORD_SECRET)" \
    | chpasswd -e
fi
if [ -e /run/secrets/$UPLOAD_PASSWORD_SECRET ]; then
  UPLOAD_PASSWORD="$(cat /run/secrets/$UPLOAD_PASSWORD_SECRET)"
fi

chown $WXUSER_NAME $UPLOAD_PATH
chmod 755 /usr/local/bin/wx_upload.sh

echo "# Added by /usr/local/bin/entrypoint-wx.sh"  >/etc/crontabs/$WXUSER_NAME
ITEM=0
IFS=', ' read -r -a USERNAMES <<< "$UPLOAD_USERNAME"
for CAM in $CAMS; do
  MINUTE=$(seq -s, $ITEM $INTERVAL 60)
  if [ -e /run/secrets/wunderground-pw-cam/wunderground-pw-$CAM ]; then
    PW=$(cat /run/secrets/wunderground-pw-cam/wunderground-pw-$CAM)
  else
    PW=$UPLOAD_PASSWORD
  fi
  cat <<EOF >>/etc/crontabs/$WXUSER_NAME
$MINUTE * * * *  /usr/local/bin/wx_upload.sh $CAM $UPLOAD_HOSTNAME $UPLOAD_PATH
EOF
  ncftpini=/dev/shm/$WXUSER_NAME-ncftp-$CAM
  cat <<EOF >$ncftpini
host $UPLOAD_HOSTNAME
user ${USERNAMES[$ITEM]}
pass $PW
EOF
  chown $WXUSER_NAME $ncftpini && chmod 600 $ncftpini
  ln -s $ncftpini /home/$WXUSER_NAME/.ncftp-$CAM
  mkdir -p $UPLOAD_PATH/$CAM
  chown $WXUSER_NAME $UPLOAD_PATH/$CAM
  ITEM=$((ITEM + 1))
done

touch /var/log/cron.log /var/log/docker.log
chown $WXUSER_NAME /var/log/docker.log
crond -L /var/log/cron.log
tail -f -n0 /var/log/cron.log /var/log/docker.log &

# Not using mod_delay: suppress warning messages in logs
cat >/etc/proftpd/conf.d/mod_delay.conf <<EOF
<IfModule mod_delay.c>
    DelayEngine off
</IfModule>
EOF
echo 'TransferLog /var/log/docker.log' > /etc/proftpd/conf.d/logging.conf

# Invoke base proftpd image's entrypoint
exec /usr/local/bin/entrypoint.sh
