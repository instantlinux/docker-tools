#! /bin/bash
mkdir -m 700 /root/.ssh
if [ $SYNC_ROLE == "primary" ]; then
  echo "0-59/$SYNC_INTERVAL * * * *   root  /root/src/swarm-sync.sh" \
   >/etc/cron.d/swarm-sync

  cp /var/run/secrets/swarm-sync_sshkey /root/.ssh/swarm-sync-sshkey.rsa
  chmod 400 /root/.ssh/swarm-sync-sshkey.rsa

  if [ ! -e /root/.unison/common.prf ]; then
    # configuration files files are *.prf; don't overwrite after initial
    # installation
    cp /root/src/*.prf /root/.unison
  fi
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
  /etc/init.d/ssh start
  echo "$SYNC_SSHKEY" >>/root/.ssh/authorized_keys
fi
touch /var/log/unison/unison.log
tail -f /var/log/unison/unison.log
