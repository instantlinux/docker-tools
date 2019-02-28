#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$PASV_ADDRESS" ]; then
  echo "** This container will not run without setting for PASV_ADDRESS **"
  sleep 10
  exit 1
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
pasv_address=$PASV_ADDRESS
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

# Invoke as a child process; version 3.0.3 crashes if run as PID 1
# See https://github.com/InfrastructureServices/vsftpd/commit/970711fde95bee3de1e4a5e0b557c3132d0c3e3f
vsftpd /etc/vsftpd/vsftpd.conf
