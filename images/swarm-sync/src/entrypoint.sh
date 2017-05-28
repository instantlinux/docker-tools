#! /bin/sh
mkdir -m 700 /root/.ssh
if [ $SYNC_ROLE == "primary" ]; then
  mkdir -p /etc/cron.d
  echo "0-59/$SYNC_INTERVAL * * * *   root  /root/src/swarm-sync.sh" \
   >/etc/cron.d/swarm-sync

  cp /run/secrets/$SECRET /run/$SECRET.rsa
  chmod 400 /run/$SECRET.rsa
  ln -s /run/$SECRET.rsa /root/.ssh/swarm-sync.rsa

  # configuration files files are *.prf; don't overwrite after initial
  # installation
  [ -e /root/.unison/common.prf ] || cp /root/src/*.prf /root/.unison

  RETRIES=10
  while [ ! -s /root/.ssh/known_hosts ]; do
    sleep 5
    ssh-keyscan peer >> /root/.ssh/known_hosts
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES == 0 ]; then
      echo "Could not reach sshd on peer after 10 tries"
      exit 1
    fi
  done
  cron
else
  ssh-keygen -A
  /usr/sbin/sshd
  echo "$SYNC_SSHKEY" >>/root/.ssh/authorized_keys
fi
touch /var/log/unison/unison.log
tail -f /var/log/unison/unison.log
