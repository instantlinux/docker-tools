#! /bin/bash
# Upload latest image to wunderground

CAM=$1
DEST=$2
UPLOAD_FROM=$3

MAX_SIZE=145kb
MAX_TIME=60
RETRIES=3

if [ "$CAM" == "twinpeaks" ]; then
  CROP="-crop 1920x880+0+0"
else
  CROP=""
fi

LOG=/var/log/docker.log

cd $UPLOAD_FROM/$CAM
LATEST=`find . -type f -name *.jpg -mmin -5 -print|sort -r |head -1`
IMG=/tmp/image-`date +%H.%M.%S`.jpg
if [ "$LATEST" != "" ]; then
  convert $LATEST $CROP -define jpeg:extent=$MAX_SIZE $IMG
  while [ $RETRIES -gt 0 ]; do
    START=`date +%s`
    ncftpput -f ~/.ncftp-$CAM -t $MAX_TIME -V -C $DEST $IMG /image.jpg
    RET=$?
    FIN=`date +%s`
    if [ $RET == 0 ]; then
      echo "I action=wx_upload result=ok file=$LATEST bytes=`stat -c %s $IMG` cam=$CAM seconds=$((FIN - START))" >> $LOG
      break
    else
      echo "F action=wx_upload result=fail file=$LATEST bytes=`stat -c %s $IMG` cam=$CAM seconds=$((FIN - START))" >> $LOG
    fi
    RETRIES=$((RETRIES - 1))
    sleep 5
  done
  rm $IMG
fi
