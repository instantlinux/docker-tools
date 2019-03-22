#!/bin/sh -e

mkdir -p /root/.ssh
if [ ! -f /root/.ssh/id_rsa ]; then
  if [ -f /run/secrets/git-deploy-sshkey ]; then
    cp /run/secrets/git-deploy-sshkey /root/.ssh/id_rsa
    chmod 400 /root/.ssh/id_rsa
  fi
  host=`echo $GIT_HOST | cut -d : -f 1`
  port=22
  echo $GIT_HOST | grep -q : && port=`echo $GIT_HOST | cut -d : -f 2`
  RETRIES=10
  while [ ! -s /tmp/sshkey ]; do
    sleep 5
    ssh-keyscan -p $port $host > /tmp/sshkey
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES == 0 ]; then
      echo "Could not reach sshd on $host after 10 tries"
      exit 1
    fi
  done
  cat /tmp/sshkey >> /root/.ssh/known_hosts && rm /tmp/sshkey
fi
cd /git/$DEST
if [ ! -d .git ]; then
  git clone $GIT_REPO $DEST
fi
LAST_HASH=
RETVAL=0
while [ 1 == 1 ]; do
  if ! git fetch; then
    echo Cannot fetch repo=$GIT_REPO status=warning
    RETVAL=1
  else
    HASH=`git rev-parse refs/remotes/origin/$GIT_COMMIT`
    git checkout $GIT_COMMIT -q
    if [ "$HASH" != "$LAST_HASH" ]; then
      git pull origin $GIT_COMMIT
      [ $? -ne 0 ] && exit 1
      echo `date --rfc-2822` updating to hash=$HASH
      LAST_HASH=$HASH
    fi
  fi
  [ $INTERVAL -eq 0 ] && break
  sleep $INTERVAL
done
exit $RETVAL
