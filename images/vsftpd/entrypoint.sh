#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -e /run/secrets/$FTPUSER_PASSWORD_SECRET ]; then
  adduser -u $FTPUSER_UID -s /bin/sh -g "ftp user" -D $FTPUSER_NAME
  echo "$FTPUSER_NAME:$(cat /run/secrets/$FTPUSER_PASSWORD_SECRET)" \
    | chpasswd -e
fi

# There is a vexing problem with permissions of /dev/stdout under
# Docker, gave up trying to fix symlink issues. Here's the workaround.

if [ "$VSFTPD_LOG_FILE" == /dev/stdout ]; then
  VSFTPD_LOG_FILE=/var/log/stdout.txt
  touch $VSFTPD_LOG_FILE
  tail -f -n 0 $VSFTPD_LOG_FILE &
fi    

cat <<EOF >/etc/vsftpd/vsftpd.conf
anon_mkdir_write_enable=$ANON_MKDIR_WRITE_ENABLE
anon_upload_enable=$ANON_UPLOAD_ENABLE
anonymous_enable=$ANONYMOUS_ENABLE
listen=YES
local_enable=YES
local_umask=$LOCAL_UMASK
log_ftp_protocol=$LOG_FTP_PROTOCOL
nopriv_user=vsftp
pasv_enable=YES
pasv_max_port=$PASV_MAX_PORT
pasv_min_port=$PASV_MIN_PORT
seccomp_sandbox=NO
use_localtime=$USE_LOCALTIME
vsftpd_log_file=$VSFTPD_LOG_FILE
write_enable=$WRITE_ENABLE
xferlog_enable=YES
EOF

if [ "$(ls -A /etc/vsftpd.d)" ]; then
  cat /etc/vsftpd.d/* >> /etc/vsftpd/vsftpd.conf
fi

exec vsftpd /etc/vsftpd/vsftpd.conf
