#! /bin/sh

API_PASSWORD=$(cat /run/secrets/$SECRET)

if [ ! -e /etc/nut/.setup ]; then
  cat <<EOF >>/etc/nut/ups.conf
[$NAME]
        driver = $DRIVER
        port = $PORT
        serial = "$SERIAL"
        desc = "$DESCRIPTION"
EOF
  cat <<EOF >>/etc/nut/upsd.conf
LISTEN 0.0.0.0
EOF
  cat <<EOF >>/etc/nut/upsd.users
[$API_USER]
        password = $API_PASSWORD
        upsmon $SERVER
EOF
  cat <<EOF >>/etc/nut/upsmon.conf
MONITOR $NAME@localhost 1 $API_USER $API_PASSWORD $SERVER
RUN_AS_USER $USER
EOF
  touch /etc/nut/.setup
fi

mkdir -p -m 2750 /var/run/nut
chown $USER.$GROUP /var/run/nut

/usr/sbin/upsdrvctl -u root start
/usr/sbin/upsd -u nut
exec /usr/sbin/upsmon -D
