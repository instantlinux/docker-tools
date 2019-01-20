#! /bin/sh -e

API_PASSWORD=$(cat /run/secrets/$SECRET)

if [ ! -e /etc/nut/.setup ]; then
  if [ -e /etc/nut/local/ups.conf ]; then
    cp /etc/nut/local/ups.conf /etc/nut/ups.conf
  else
    cat <<EOF >>/etc/nut/ups.conf
[$NAME]
        driver = $DRIVER
        port = $PORT
        serial = "$SERIAL"
        desc = "$DESCRIPTION"
EOF
    if [ ! -z "$VENDORID" ]; then
      echo "        vendorid = $VENDORID" >> /etc/nut/ups.conf
    fi
  fi
  if [ -e /etc/nut/local/ups.conf ]; then
    cp /etc/nut/local/ups.conf /etc/nut/ups.conf
  else
    cat <<EOF >>/etc/nut/upsd.conf
LISTEN 0.0.0.0
EOF
  fi
  if [ -e /etc/nut/local/upsd.users ]; then
    cp /etc/nut/local/upsd.users /etc/nut/upsd.users
  else
    cat <<EOF >>/etc/nut/upsd.users
[$API_USER]
        password = $API_PASSWORD
        upsmon $SERVER
EOF
  fi
  if [ -e /etc/nut/local/upsmon.conf ]; then
    cp /etc/nut/local/upsmon.conf /etc/nut/upsmon.conf
  else
    cat <<EOF >>/etc/nut/upsmon.conf
MONITOR $NAME@localhost 1 $API_USER $API_PASSWORD $SERVER
RUN_AS_USER $USER
EOF
  fi
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
/usr/sbin/upsd -u $USER
exec /usr/sbin/upsmon -D
