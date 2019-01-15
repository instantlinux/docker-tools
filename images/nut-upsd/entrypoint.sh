#! /bin/sh -e

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
else
  # restarting - eliminate flakiness noted in issue #7
  killall upsmon || true
  rm -f /var/run/nut/upsd.pid    
fi

mkdir -m 2750 /dev/shm/nut
chown $USER.$GROUP /dev/shm/nut
[ -e /var/run/nut ] || ln -s /dev/shm/nut /var/run

/usr/sbin/upsdrvctl -u root start
/usr/sbin/upsd -u nut
exec /usr/sbin/upsmon -D
