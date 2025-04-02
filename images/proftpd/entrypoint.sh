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

if [ -e /run/secrets/$FTPUSER_SECRETNAME ] && ! id -u "$FTPUSER_NAME"; then
  adduser -u $FTPUSER_UID -s /bin/sh -g "ftp user" -D $FTPUSER_NAME
  echo "$FTPUSER_NAME:$(cat /run/secrets/$FTPUSER_SECRETNAME)" \
    | chpasswd -e
fi

if [ "$SFTP_ENABLE" = "on" ]; then
  mkdir -p /etc/ssh
  test -f /etc/ssh/ssh_host_rsa_key   || ssh-keygen -m PEM -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa -b 2048
  test -f /etc/ssh/ssh_host_ecdsa_key || ssh-keygen -m PEM -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521

  sed -i -e "/^Port/s/^/#/" /etc/proftpd/proftpd.conf
  
  sed -i \
      -e "s/^#\(  SFTPEngine on\)/\1/" \
      -e "s/^#\(  Port 2222.*\)/  Port $SFTP_PORT/" \
      -e "s/^#\(  SFTPCompression delayed\)/\1/" \
      -e "s/^#\(  SFTPHostKey .*ssh_host_rsa_key\)/\1/" \
      -e "s/dsa_key/ssh_host_dsa_key (NO LONGER SUPPORTED)/" \
      /etc/proftpd/conf.d/sftp.conf
fi

if [ "$ANONYMOUS_DISABLE" = "on" ]; then
  sed -i '/<Anonymous/,/<\/Anonymous>/d' /etc/proftpd/proftpd.conf
else
  sed -i \
      -e "s:{{ ANONYMOUS_DISABLE }}:$ANONYMOUS_DISABLE:" \
      -e "s:{{ ANON_UPLOAD_ENABLE }}:$ANON_UPLOAD_ENABLE:" \
      /etc/proftpd/proftpd.conf
fi

mkdir -p /run/proftpd && chown proftpd /run/proftpd/

sed -i \
    -e "s:{{ ALLOW_OVERWRITE }}:$ALLOW_OVERWRITE:" \
    -e "s:{{ LOCAL_UMASK }}:$LOCAL_UMASK:" \
    -e "s:{{ MAX_CLIENTS }}:$MAX_CLIENTS:" \
    -e "s:{{ MAX_INSTANCES }}:$MAX_INSTANCES:" \
    -e "s:{{ PASV_ADDRESS }}:$PASV_ADDRESS:" \
    -e "s:{{ PASV_MAX_PORT }}:$PASV_MAX_PORT:" \
    -e "s:{{ PASV_MIN_PORT }}:$PASV_MIN_PORT:" \
    -e "s+{{ SERVER_NAME }}+$SERVER_NAME+" \
    -e "s:{{ TIMES_GMT }}:$TIMES_GMT:" \
    -e "s:{{ WRITE_ENABLE }}:$WRITE_ENABLE:" \
    /etc/proftpd/proftpd.conf

exec proftpd --nodaemon -c /etc/proftpd/proftpd.conf
