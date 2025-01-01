#!/bin/sh
# $Id$
#
# Created 3/29/2014 by richb
#  Trigger the git dump scripts from cron

# Parameters
#  $1 git backup dir
#  $2 number of files to keep
#  $3-$ git repo suffixes

# Omit git repo list if a API_TOKEN_SECRETNAME is provided to query project
# list from gitlab

DESTDIR=$1
shift;

log_entry () {
 IL_PRIORITY=$1
 IL_MSG=$2

 if [ ! -z "$LOGFILE" ]; then
   echo `date +"%h %d %H:%M:%S"` $IL_PRIORITY "$IL_MSG" >> $LOGFILE
 fi
 return 0
}

KEEP_DAYS=$1
shift;
ERROR_STATE=0
[ -e /etc/opt/git-dump ] && source /etc/opt/git-dump
log_entry info status=START

# Dumps will be kept in directories named as day of week or
# day of month if 31 or less; else combine month+day if longer

if [ $KEEP_DAYS == 7 ]
then
 DAY=`date +%a`
elif [ $KEEP_DAYS -le 31 ]
then
 DAY=`date +%d`
else
 DAY=`date +%m%d`
fi

if [ ! -z "$API_TOKEN_SECRETNAME" ] && [ -e /run/secrets/$API_TOKEN_SECRETNAME ]; then
  SSH_HOST=$(echo $REPO_PREFIX | cut -d@ -f 2 | cut -d/ -f 1 | cut -d: -f 1)
  TOKEN=$(cat /run/secrets/$API_TOKEN_SECRETNAME)
  if [ $SCM_TYPE == github ]; then
    API_VERSION=v3
    API_PATH=repo
    AUTH_HEADER='Authorization: token'
    RESULT_PATH='.[].name'
    # TODO github not yet working
  elif [ $SCM_TYPE == gitlab ]; then
    API_VERSION=v4
    API_PATH=projects
    AUTH_HEADER=PRIVATE-TOKEN:
    RESULT_PATH='.[].name'
  elif [ $SCM_TYPE == gitea ]; then
    API_VERSION=v1
    API_PATH=repos/search
    AUTH_HEADER='Authorization: token'
    RESULT_PATH='.data[].full_name'
    [[ $REPO_PREFIX = git@* ]] && REPO_PREFIX=ssh://$REPO_PREFIX
  fi

  curl -s -k --header "$AUTH_HEADER $TOKEN" \
    https://$SSH_HOST/api/$API_VERSION/$API_PATH > /tmp/projects.json
  ITEMS=$(jq -r $RESULT_PATH /tmp/projects.json | sort)
else
  ITEMS=$@
fi

count=0
for ITEM in $ITEMS; do
  SUBDIR=$(basename $ITEM)
  [ -d $DESTDIR/$SUBDIR/$DAY ] || mkdir -p -m 2750 $DESTDIR/$SUBDIR/$DAY
  BACKUP_TARGET=$DESTDIR/$SUBDIR/$DAY/$SUBDIR.bundle
  log_entry info " -- Invoking git clone / bundle repo=item subdir=$SUBDIR"
  cd $DESTDIR/$SUBDIR/$DAY
  git clone $REPO_PREFIX$ITEM ./current
  if [ $? != 0 ]; then
    log_entry error " xx $REPO_PREFIX$ITEM could not be cloned"
    ERROR_STATE=1
  else
    cd current
    git bundle create $BACKUP_TARGET --all
    [ $? != 0 ] && ERROR_STATE=1
    cd ..
    rm -fr ./current
    count=$((count + 1))
  fi
done


if [ $ERROR_STATE != 0 ]
then
  log_entry info status=ABORTED
  exit 1
fi

if [ ! -z "$STATFILE" ]; then
  echo "`date --rfc-2822` dumped $ITEMS" > $STATFILE
fi
log_entry info status=FINISH count=$count

exit 0
