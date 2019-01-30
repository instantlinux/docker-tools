#! /bin/sh -e
# TODO: rsync needs a separate secret from unison, so for now the
#  script cannot support the more-efficient rsync method for large files
#  https://serverfault.com/questions/749474/ssh-authorized-keys-command-option-multiple-commands

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
  if [ ! -s /run/secrets/$SECRET ]; then
    echo "** This container will not run without secret $SECRET **"
    sleep 10
    exit 1
  fi
  if [ -z "$PEERNAME" ]; then
    echo "** This container will not run without setting for PEERNAME **"
    sleep 10
    exit 1
  fi
  cp /run/secrets/$SECRET /run/$SECRET.rsa
  chmod 400 /run/$SECRET.rsa
  ln -s /run/$SECRET.rsa /root/.ssh/data-sync.rsa
  cat <<EOF >/root/.unison/default.prf
# Path specifications for unison
root = /var
root = ssh://$PEERNAME//var
path = data-sync
include common
EOF

  # Add a default configuration file if not present
  if [ ! -e /root/.unison/common.prf ]; then
    if [ -d /etc/unison.d ] && [ "$(ls -A /etc/unison.d)" ]; then
      cp -a /etc/unison.d/. /root/.unison
    else
      cp /root/src/*.prf /root/.unison
    fi
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
  echo "$SYNC_SSHKEY" >>/root/.ssh/authorized_keys
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
