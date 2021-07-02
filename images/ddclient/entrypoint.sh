#!/bin/sh -xe

USER_PASSWORD=$(cat /run/secrets/$USER_SECRET)

if [ ! -e /etc/ddclient/ddclient.conf ]; then
    cat <<EOF > /etc/ddclient/ddclient.conf
daemon=$INTERVAL
pid=/run/ddclient/ddclient.pid
use=web
web=$IPLOOKUP_URI
ssl=yes

server=members.easydns.com, protocol=$SERVICE_TYPE, login=$USER_LOGIN, password=$USER_PASSWORD $HOST
EOF
fi
mkdir -p /run/ddclient && chown ddclient /run/ddclient

exec su-exec ddclient /usr/bin/ddclient -foreground
