#!/bin/sh

DB_PASS=`cat /run/secrets/weewx-db-password`
WUNDER_PASS=`cat /run/secrets/weewx-wunderground-password`
WUNDER_API_KEY=`cat /run/secrets/weewx-wunderground-apikey`
SSHKEY=weewx-rsync-sshkey
HOMEDIR=/home/weewx
PATH=$HOMEDIR/bin:$PATH

if [ ! -e $HOMEDIR/weewx.conf.bak ]; then
  # At first startup, set timezone and other configs from environment
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
  wee_config_device --set-interval $LOGGING_INTERVAL
  wee_config_device --set-rain-year-start $RAIN_YEAR_START
  wee_config_device --set-tz-code $TZ_CODE
  sed -i -e "s+-/var/log/messages+$SYSLOG_DEST+" /etc/rsyslog.conf

  sed --in-place=.bak -e "s/location = DESC/location = \"$LOCATION\"/" \
  -e "s/latitude = 90.0/latitude = $LATITUDE/" \
  -e "s/longitude = 90.0/longitude = $LONGITUDE/" \
  -e "s/altitude = 0, foot/altitude = $ALTITUDE/" \
  -e "s/rain_year_start = 1/rain_year_start = $RAIN_YEAR_START/" \
  -e "s/week_start = 6/week_start = $WEEK_START/" \
  -e "s:HTML_ROOT = public_html:HTML_ROOT = $HTML_ROOT:" \
  -e "s/#station  = your Weather/station = $STATION_ID  #/" \
  -e "s/#password = your Weather Und/password = $WUNDER_PASS  # Und/" \
  -e "s/location = \"INSERT_LOCATION_HERE /location = \"$XTIDE_LOCATION\"  # \"/" \
  -e "s/lid =/#lid =/" \
  -e "s/foid =/#foid =/" \
  -e "s/api_key = INSERT_WU_API_KEY_HERE/api_key = $WUNDER_API_KEY/" \
  -e "s/skin = Standard/skin = $SKIN/" \
  -e "s/driver = weedb.mysql/driver = $DB_DRIVER/" \
  -e "s/rapidfire = False/rapidfire = $RAPIDFIRE/" \
  -e "s/database = archive_sqlite/database = archive_$DB_BINDING_SUFFIX/" \
  -e "s/database = forecast_sqlite/database = forecast_$DB_BINDING_SUFFIX/" \
  -e "s/\[\[forecast_sqlite\]\]/[[forecast_$DB_BINDING_SUFFIX]]\n      host = $DB_HOST\n      user = $DB_USER\n      password = $DB_PASS\n      database_name = $DB_NAME_FORECAST\n      driver = $DB_DRIVER\n\n    [[forecast_sqlite]]/" \
  -e "s/host = localhost/host = $DB_HOST/" \
  -e "s/user = weewx/user = $DB_USER/" \
  -e "s/password = weewx/password = $DB_PASS/" \
  -e "s/database_name = weewx$/database_name = $DB_NAME/" \
  -e "s/#server = replace with your/server = $RSYNC_HOST  #/" \
  -e "s/#user = replace with your username/user = $RSYNC_USER/" \
  -e "s:#path = replace with the:path = $RSYNC_DEST  #:" \
  $HOMEDIR/weewx.conf
fi

rsyslogd

cp /run/secrets/$SSHKEY /run/$SSHKEY && chmod 400 /run/$SSHKEY
if [ ! -d /root/.ssh ]; then
  mkdir -m 700 /root/.ssh
  cat >/root/.ssh/config <<EOF
Host $RSYNC_HOST
  IdentityFile /run/$SSHKEY
  Port $RSYNC_PORT
  User $RSYNC_USER
EOF
  ssh-keyscan -p $RSYNC_PORT $RSYNC_HOST >>/root/.ssh/known_hosts
fi

weewxd $HOMEDIR/weewx.conf|grep -v LOOP:
# Failure: attempt restart only every 2 minutes
sleep 120
exit 1
