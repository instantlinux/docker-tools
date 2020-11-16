#!/bin/sh

PEERNAME=$1

# Reconfirm peer IP address in case it was restarted
PEER_IP=$(nslookup $PEERNAME 2&>1 |tail -3|grep -oE "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
if ! grep -q "$PEER_IP" /root/.ssh/known_hosts; then
  ssh-keyscan $PEER_IP >> /root/.ssh/known_hosts
fi

nice unison
if [ $? != 0 ]; then
  echo "$(date --rfc-2822) Error during unison run" \
   >> /var/log/unison/unison.log
else
  echo "$(date --rfc-2822) ok" > /var/log/unison/unison-status.txt
fi
