#/bin/sh

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

ETC=/etc/dovecot
if [ -s $ETC/conf.local/dovecot.conf ]; then
  cp -a $ETC/conf.local/dovecot.conf $ETC
fi
if [ -s $ETC/conf.local/dovecot-ldap.conf ]; then
  cp $ETC/conf.local/dovecot-ldap.conf $ETC
  sed -i -e "s/PASSWORD/`cat /run/secrets/$LDAP_PASSWD_SECRET`/" \
    $ETC/dovecot-ldap.conf
fi
mkdir -p -m 700 /etc/ssl/private
cp /run/secrets/*key.pem /etc/ssl/private

/usr/sbin/dovecot

exec /root/entrypoint.sh
