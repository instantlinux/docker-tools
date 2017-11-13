#! /bin/sh
mkdir -m 700 /root/.ssh
if [ $SYNC_ROLE == "primary" ]; then
  echo "0-59/$SYNC_INTERVAL * * * *   /root/src/swarm-sync.sh $PEERNAME" \
       | crontab -
  cp /run/secrets/$SECRET /run/$SECRET.rsa
  chmod 400 /run/$SECRET.rsa
  ln -s /run/$SECRET.rsa /root/.ssh/swarm-sync.rsa

  # configuration files files are *.prf; don't overwrite after initial
  # installation
  [ -e /root/.unison/common.prf ] || cp /root/src/*.prf /root/.unison

  RETRIES=10
  while [ ! -s /tmp/peerkey ]; do
    sleep 5
    ssh-keyscan $PEERNAME > /tmp/peerkey
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES == 0 ]; then
      echo "Could not reach sshd on $PEERNAME after 10 tries"
      exit 1
    fi
  done
  mv /tmp/peerkey /root/.ssh/known_hosts
  crond
else
  ssh-keygen -A
  /usr/sbin/sshd
  echo "$SYNC_SSHKEY" >>/root/.ssh/authorized_keys
fi
touch /var/log/unison/unison.log
tail -f -n 1 /var/log/unison/unison.log
