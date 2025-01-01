#! /bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$REPOS" ] && [ ! -s /run/secrets/$API_TOKEN_SECRETNAME ]; then
  echo "** This container requires setting for REPOS or API_TOKEN_SECRETNAME **"
  sleep 10
  exit 1
fi

SSH_PATH=/home/$USERNAME/.ssh
mkdir -p -m 700 $SSH_PATH
if [ ! -z "$SSHKEY_SECRETNAME" ]; then
  cp /run/secrets/$SSHKEY_SECRETNAME $SSH_PATH/$SSHKEY_SECRETNAME
  chmod 400 $SSH_PATH/$SSHKEY_SECRETNAME
  cat <<EOF >$SSH_PATH/config
Host *
 IdentityFile $SSH_PATH/$SSHKEY_SECRETNAME
 Port $SSH_PORT
EOF
  if [ ! -z "$REPO_PREFIX" ]; then
    SSH_HOST=$(echo $REPO_PREFIX | cut -d@ -f 2 | cut -d/ -f 1| cut -d: -f 1)
    RETRIES=10
    while [ ! -s /tmp/sshkey ]; do
      sleep 5
      ssh-keyscan -p $SSH_PORT $SSH_HOST > /tmp/sshkey
      RETRIES=$((RETRIES - 1))
      if [ $RETRIES == 0 ]; then
        echo "Could not reach sshd on $SSH_HOST after 10 tries"
        exit 1
      fi
    done
    cat /tmp/sshkey >> $SSH_PATH/known_hosts && rm /tmp/sshkey
  fi
fi
chown -R $USERNAME /home/$USERNAME
[ -e /var/log/git-dump.log ] || touch /var/log/git-dump.log
[ -e /var/log/git-dump-status.txt ] || touch /var/log/git-dump-status.txt
mkdir -p -m 750 $DEST_DIR
chown $USERNAME:$GROUP $DEST_DIR /var/log/git-dump.log /var/log/git-dump-status.txt

cat <<EOF >/etc/opt/git-dump
# Options for /usr/local/bin/git-dump
API_TOKEN_SECRETNAME=$API_TOKEN_SECRETNAME
LOGFILE=/var/log/git-dump.log
REPO_PREFIX=$REPO_PREFIX
STATFILE=/var/log/git-dump-status.txt
EOF
cat <<EOF >/etc/crontabs/$USERNAME
$MINUTE $HOUR * * *  /usr/local/bin/git-dump.sh $DEST_DIR $KEEP_DAYS $REPOS
EOF

crond -L /var/log/cron.log
tail -fn 1 /var/log/git-dump.log
