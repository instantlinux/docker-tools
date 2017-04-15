#! /bin/bash
mkdir -m 700 /root/.ssh
if [ $SYNC_ROLE == "primary" ]; then
  echo "0-59/$SYNC_INTERVAL * * * *   root  /root/src/swarm-sync.sh" \
   >/etc/cron.d/swarm-sync

  # TODO: install docker 17.03 for secrets
  echo $SYNC_SSHPEM | sed 's/,/\n/g' > /root/.ssh/swarm-sync-sshkey.rsa
  # cp /var/run/secrets/swarm-sync-sshkey /root/.ssh/swarm-sync-sshkey.rsa
  chmod 400 /root/.ssh/swarm-sync-sshkey.rsa

  if [ ! -e /root/.unison/common.prf ]; then
    # configuration files files are *.prf; don't overwrite after initial
    # installation
    cp /root/src/*.prf /root/.unison
  fi
  sleep 10
  ssh-keyscan peer >> /root/.ssh/known_hosts
  cron
else
  /etc/init.d/ssh start
  echo "$SYNC_SSHKEY" >>/root/.ssh/authorized_keys
fi
touch /var/log/unison/unison.log
tail -f /var/log/unison/unison.log
