#! /bin/sh

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

SSH_PATH=/home/$USERNAME/.ssh
mkdir -p -m 700 $SSH_PATH
if [ ! -z "$SSHKEY_SECRET" ]; then
  cp /run/secrets/$SSHKEY_SECRET $SSH_PATH/$SSHKEY_SECRET
  chmod 400 $SSH_PATH/$SSHKEY_SECRET
  cat <<EOF >$SSH_PATH/config
Host *
 IdentityFile $SSH_PATH/$SSHKEY_SECRET
 Port $SSH_PORT
EOF
  if [ ! -z "$REPO_PREFIX" ]; then
    SSH_HOST=$(echo $REPO_PREFIX | cut -d@ -f 2 | cut -d: -f 1)
    ssh-keyscan -p $SSH_PORT $SSH_HOST >>$SSH_PATH/known_hosts
  fi
fi
chown -R $USERNAME /home/$USERNAME
[ -e /var/log/git-dump.log ] || touch /var/log/git-dump.log
[ -e /var/log/git-dump-status.txt ] || touch /var/log/git-dump-status.txt
mkdir -p -m 750 $DEST_DIR
chown $USERNAME.$GROUP $DEST_DIR /var/log/git-dump.log /var/log/git-dump-status.txt

cat <<EOF >/etc/opt/git-dump
# Options for /usr/local/bin/git-dump
API_TOKEN_SECRET=$API_TOKEN_SECRET
LOGFILE=/var/log/git-dump.log
REPO_PREFIX=$REPO_PREFIX
STATFILE=/var/log/git-dump-status.txt
EOF
cat <<EOF >/etc/crontabs/$USERNAME
$MINUTE $HOUR * * *  /usr/local/bin/git-dump.sh $DEST_DIR $KEEP_DAYS $REPOS
EOF

crond -L /var/log/cron.log
tail -fn 1 /var/log/git-dump.log
