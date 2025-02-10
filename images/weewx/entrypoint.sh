#!/bin/sh -e

DB_PASS=$(cat /run/secrets/weewx-db-password)
WUNDER_PASS=$(cat /run/secrets/weewx-wunderground-password)
WUNDER_API_KEY=$(cat /run/secrets/weewx-wunderground-apikey)
SSHKEY=weewx-rsync-sshkey
WX_GROUP=dialout
HOMEDIR=/home/$WX_USER
PATH=$HOMEDIR/weewx-venv/bin:$PATH

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cat /usr/share/zoneinfo/$TZ > /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ ! -e $WX_ROOT/weewx.conf.bak ]; then
  if [ -z ${STATION_URL/ /} ]; then
    REGISTER_OPT=false
  else
    REGISTER_OPT=true
  fi
  # Edit distributed weewx.conf settings after adding driver for STATION_TYPE
  cp /etc/rsyslog.conf /tmp
  sed -e "s+-/var/log/messages+$SYSLOG_DEST+" \
      -e 's/^.*imklog/# disabled ("imklog/' \
      /tmp/rsyslog.conf >/etc/rsyslog.conf
  su $WX_USER -c "weectl station reconfigure --driver=weewx.drivers.$(
    echo $STATION_TYPE | tr [:upper:] [:lower:]) --no-prompt"
  sed --in-place=.bak -e "s/location = DESC/location = \"$LOCATION\"/" \
  -e "s/altitude = 0, foot/altitude = $ALTITUDE/" \
  -e "s/archive_interval =.*/archive_interval = $LOGGING_INTERVAL/" \
  -e "s/debug = 0/debug = $DEBUG/" \
  -e "s/latitude =.*/latitude = $LATITUDE/" \
  -e "s/longitude =.*/longitude = $LONGITUDE/" \
  -e "s:port = /dev/.*:port = $DEVICE_PORT:" \
  -e "s/rain_year_start =.*/rain_year_start = $RAIN_YEAR_START/" \
  -e "s/station_type =.*/station_type = $STATION_TYPE/" \
  -e "s/register_this_station = .*/register_this_station = $REGISTER_OPT/" \
  -e "s/week_start = 6/week_start = $WEEK_START/" \
  -e "s:HTML_ROOT = public_html:HTML_ROOT = $HTML_ROOT:" \
  -e "s/ station =.*/ station = $STATION_ID/" \
  -e "s+#station_url =.*+station_url = $STATION_URL+" \
  -e "s/password = replace_me$/password = $WUNDER_PASS  # Und/" \
  -e "s/lid =/#lid =/" \
  -e "s/foid =/#foid =/" \
  -e "s/api_key = INSERT_WU_API_KEY_HERE/api_key = $WUNDER_API_KEY/" \
  -e "s/driver = weedb.mysql/driver = $DB_DRIVER/" \
  -e "s/rapidfire = False/rapidfire = $RAPIDFIRE/" \
  -e "s/database = archive_sqlite/database = archive_$DB_BINDING_SUFFIX/" \
  -e "s/host = localhost/host = $DB_HOST/" \
  -e "s/user = weewx/user = $DB_USER/" \
  -e "s/password = weewx/password = $DB_PASS/" \
  -e "s/database_name = weewx$/database_name = $DB_NAME/" \
  -e "s/server = replace_me/server = $RSYNC_HOST/" \
  -e "s/user = replace_me/user = $RSYNC_USER/" \
  -e "s:path = replace_me:path = $RSYNC_DEST:" \
  $WX_ROOT/weewx.conf
  if [ -e $WX_ROOT/skins/WeeGreen/skin.conf ]; then
    sed -i -e "s/ID=[A-Z0-9]$/ID=$STATION_ID/" \
      -e "s/computerType =.*/computerType = $COMPUTER_TYPE/" \
      -e "s/modelNumber =.*/modelNumber = $STATION_MODEL/" \
      -e "s/modelFeatures =.*/modelFeatures = $STATION_FEATURES/" \
      -e "s/[#]*optionalAccessories = .*/optionalAccessories = $OPTIONAL_ACCESSORIES/" \
      -e "s/siteOperator =.*/siteOperator = $OPERATOR/" \
      -e "s+webcamLink = .*+webcamLink = $WEBCAM_URL+" \
      $WX_ROOT/skins/WeeGreen/skin.conf
  fi
  if [ "$AIRLINK_HOST" != "" ]; then
    sed -i -e "s/hostname = airlink$/hostname = $AIRLINK_HOST/" \
      $WX_ROOT/weewx.conf
  else
    su $WX_USER -c "weectl extension uninstall --yes airlink"
  fi
  if [ $SKIN != Season ]; then
    sed -i \
      "/skin = Season/,/enable = true/c skin = Seasons\n enable = false" $WX_ROOT/weewx.conf
    sed -i \
      "/skin = Standard/,/enable = false/c skin = $SKIN\n enable = true" $WX_ROOT/weewx.conf
  fi

  # Change the 5th "enable = false" which is Wunderground StdRESTful toggle
  awk '/enable = false/{c++;if(c==5){sub("enable = false","enable = true");c=0}}1' \
    $WX_ROOT/weewx.conf > $WX_ROOT/weewx.conf.new
  mv $WX_ROOT/weewx.conf $WX_ROOT/weewx.conf.awk
  mv $WX_ROOT/weewx.conf.new $WX_ROOT/weewx.conf

  # At first startup, set configs from environment
  su $WX_USER -c \
  "weectl device --set-interval=$(( $LOGGING_INTERVAL / 60 )) &&
   weectl device --set-rain-year-start=$RAIN_YEAR_START &&
   weectl device --set-tz-code=$TZ_CODE"
fi

TZ=UTC rsyslogd

cp /run/secrets/$SSHKEY /run/$SSHKEY && chmod 400 /run/$SSHKEY
if [ ! -d $HOMEDIR/.ssh ]; then
  mkdir -m 700 $HOMEDIR/.ssh
  cat >$HOMEDIR/.ssh/config <<EOF
Host $RSYNC_HOST
  IdentityFile /run/$SSHKEY
  Port $RSYNC_PORT
  User $RSYNC_USER
EOF
  RETRIES=10
  while [ ! -s /tmp/sshkey ]; do
    sleep 5
    ssh-keyscan -p $RSYNC_PORT $RSYNC_HOST > /tmp/sshkey
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES == 0 ]; then
      echo "Could not reach sshd on $RSYNC_HOST after 10 tries"
      exit 1
    fi
  done
  cat /tmp/sshkey >> $HOMEDIR/.ssh/known_hosts && rm /tmp/sshkey
fi

chown -R $WX_USER $HOMEDIR/.ssh $HTML_ROOT /run/$SSHKEY
# Docker 18.02 changes group to root at launch
#chgrp $WX_GROUP /dev/ttyUSB0
set +e
su $WX_USER -c "PATH=$PATH weewxd|grep -v LOOP:"
# Failure: attempt restart only every 2 minutes
sleep 120
exit 1
