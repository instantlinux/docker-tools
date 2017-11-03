#!/bin/bash -xe

if [ -e /run/secrets/$WXUSER_PASSWORD_SECRET ]; then
  adduser -u $WXUSER_UID -s /bin/sh -g "ftp user" -D $WXUSER_NAME
  echo "$WXUSER_NAME:$(cat /run/secrets/$WXUSER_PASSWORD_SECRET)" \
    | chpasswd -e
fi

chown $WXUSER_NAME $UPLOAD_PATH

echo "# Added by /usr/local/bin/entrypoint-wx.sh"  >/etc/crontabs/$WXUSER_NAME
ITEM=0
IFS=', ' read -r -a USERNAMES <<< "$UPLOAD_USERNAME"
for CAM in $CAMS; do
  MINUTE="*/$INTERVAL"
  cat <<EOF >>/etc/crontabs/$WXUSER_NAME
$MINUTE * * * *  /usr/local/bin/wx_upload.sh $CAM $UPLOAD_HOSTNAME $UPLOAD_PATH
EOF
  ncftpini=/dev/shm/$WXUSER_NAME-ncftp-$CAM
  cat <<EOF >$ncftpini
host $UPLOAD_HOSTNAME
user ${USERNAMES[$ITEM]}
pass $UPLOAD_PASSWORD
EOF
  chown $WXUSER_NAME $ncftpini && chmod 600 $ncftpini
  ln -s $ncftpini /home/$WXUSER_NAME/.ncftp-$CAM
  mkdir -p $UPLOAD_PATH/$CAM
  chown $WXUSER_NAME $UPLOAD_PATH/$CAM
  ITEM=$((ITEM + 1))
done

crond -L /var/log/cron.log
tail -f -n0 /var/log/cron.log &

# Invoke base vsftpd image's entrypoint
exec /usr/local/bin/entrypoint.sh
