#! /bin/sh -e

mkdir -m 700 /root/.ssh
SYNC_ROLE=peer
if echo $HOSTNAME | grep -E '[-]([0-9]+)$'; then
  # Hostname has ordinal suffix - run sshd on host 0, unison on others
  ORDINAL=`echo $HOSTNAME | grep -oE '[-]([0-9]+)$' | cut -d - -f 2`
  if [ $ORDINAL != 0 ]; then
    SYNC_ROLE=active
    PEERNAME=`echo $HOSTNAME | rev | cut -d - -f 2- | rev`-0.`hostname -f | cut -d . -f 2-`
  fi
elif [ ! -z "$PEERNAME" ]; then
    SYNC_ROLE=active
fi

if [ $SYNC_ROLE == "active" ]; then
  if [ ! -s /run/secrets/$SSHKEY1 ] || [ ! -s /run/secrets/$SSHKEY2 ]; then
    echo "** This container will not run without secrets $SSHKEY1/$SSHKEY2 **"
    sleep 10
    exit 1
  fi
  if [ -z "$PEERNAME" ]; then
    echo "** This container will not run without setting for PEERNAME **"
    sleep 10
    exit 1
  fi
  cp /run/secrets/$SSHKEY1 /run/$SSHKEY1.rsa
  cp /run/secrets/$SSHKEY2 /run/$SSHKEY2.rsa
  chmod 400 /run/$SSHKEY1.rsa /run/$SSHKEY2.rsa
  ln -s /run/$SSHKEY1.rsa /root/.ssh/data-sync.rsa
  ln -s /run/$SSHKEY2.rsa /root/.ssh/id_rsa
  cat <<EOF >/root/.unison/default.prf
# Path specifications for unison
root = /var
root = ssh://$PEERNAME//var
path = data-sync
include common
EOF

  # Add configuration files from mounted unison.d; or use
  # defaults from src image (but don't overwrite)
  if [ -d /etc/unison.d ] && [ "$(ls -A /etc/unison.d)" ]; then
    cp -a /etc/unison.d/. /root/.unison
  elif [ ! -e /root/.unison/common.prf ]; then
    cp /root/src/*.prf /root/.unison
  fi

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
else
  ssh-keygen -A
  if [ ! -s /etc/ssh/sshd_config ]; then
    echo "AuthorizedKeysFile  .ssh/authorized_keys" > /etc/ssh/sshd_config
  fi
  echo -n "no-pty,no-agent-forwarding,no-X11-forwarding,no-port-forwarding,command=\"/usr/bin/unison -server\" $PUBKEY1" > /root/.ssh/authorized_keys
  echo -n "no-pty,no-agent-forwarding,no-X11-forwarding,no-port-forwarding,command=\"/usr/local/bin/rrsync $RRSYNC_ROOT\" $PUBKEY2" >> /root/.ssh/authorized_keys
  unison -version
  echo sshd listening
  ip addr | grep inet | grep -v 127.0.0.1
  exec /usr/sbin/sshd -D
fi

touch /var/log/unison/unison.log
tail -f -n 1 /var/log/unison/unison.log &
while [ 1 == 1 ]; do
  START=$(date +%s)
  /root/src/data-sync.sh $PEERNAME
  while [ $(( $(date +%s) - (60 * $SYNC_INTERVAL))) -lt $START ]; do
    sleep 5
  done
done
