#!/bin/sh

PEERNAME=$1

# Reconfirm peer IP address (Docker bug:
#  https://github.com/moby/moby/issues/30487)
PEER_IP=$(nslookup $PEERNAME|grep Address|cut -d ' ' -f 3)
if ! grep -q "$PEER_IP" /root/.ssh/known_hosts; then
  ssh-keyscan $PEER_IP >> /root/.ssh/known_hosts
fi

nice unison
if [ $? != 0 ]; then
  echo "`date --rfc-3339=seconds` Error during unison run" \
   >> /var/log/unison/unison.log
else
  echo "`date --rfc-2822` ok" > /var/log/unison/unison-status.txt
fi
