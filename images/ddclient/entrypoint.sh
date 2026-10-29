#!/bin/sh -e

USER_PASSWORD=$(cat /run/secrets/$USER_SECRETNAME)

if [ -z "$HOST" ]; then
    echo "** HOST must be specified **"
    exit 1
fi

if [ ! -e /etc/ddclient/ddclient.conf ]; then
    cat <<EOF > /etc/ddclient/ddclient.conf
daemon=$INTERVAL
pid=/run/ddclient/ddclient.pid
use=web
web=$IPLOOKUP_URI
ssl=yes

server=$SERVER, protocol=$SERVICE_TYPE, login=$USER_LOGIN, password=$USER_PASSWORD $HOST
EOF
fi
chmod 400 /etc/ddclient/ddclient.conf

exec /usr/bin/ddclient -foreground -verbose
