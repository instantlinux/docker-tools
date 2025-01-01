#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if ! ls -A /run/secrets/*key.pem; then
  echo "** Must provide ssl_dh key secret (smtpd-key.pem) **"
  sleep 10
  exit 1
fi

ETC=/etc/dovecot
export SSLDIR=/etc/ssl/dovecot
if [ ! -f $SSLDIR/server.pem ]; then
  cd /etc/dovecot
  mkdir $SSLDIR/certs $SSLDIR/private
  /usr/local/bin/mkcert.sh
  ln -s $SSLDIR/certs/dovecot.pem $SSLDIR/server.pem
  ln -s $SSLDIR/private/dovecot.pem $SSLDIR/server.key
fi
if [ -s $ETC/conf.local/dovecot.conf ]; then
  cp $ETC/conf.local/dovecot.conf $ETC
fi
if [ -z "$SSH_DH" ]; then
  openssl dhparam -dsaparam -out $ETC/dh.pem 4096
  echo "ssl_dh = <$ETC/dh.pem" >> $ETC/dovecot.conf
else
  echo "ssl_dh = <$ETC/conf.local/$SSH_DH" >> $ETC/dovecot.conf
fi
if [ -s $ETC/conf.local/dovecot-ldap.conf ]; then
  cp $ETC/conf.local/dovecot-ldap.conf $ETC
  if [ -s /run/secrets/$LDAP_SECRETNAME ]; then
    sed -i -e "s/PASSWORD/`cat /run/secrets/$LDAP_SECRETNAME`/" \
      $ETC/dovecot-ldap.conf
  else
    echo "** Config dovecot-ldap.conf secret $LDAP_SECRETNAME unspecified **"
  fi
fi
if [ -f /etc/postfix/transport ]; then
  postmap /etc/postfix/transport
fi
mkdir -p -m 700 /etc/ssl/private
cp /run/secrets/*key.pem /etc/ssl/private

/usr/sbin/dovecot

# Chain to postfix entrypoint
exec /root/entrypoint.sh
