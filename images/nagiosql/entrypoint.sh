#!/bin/sh -xe

PATH=$PATH:/opt/nagios/bin
NAGIOS_ETC=/opt/nagios/etc
NAGIOS_OBJ=$NAGIOS_ETC/objects

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  ln -fns /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -e /run/secrets/$DB_PASSWD_SECRET ]; then
  DB_PASS=$(cat /run/secrets/$DB_PASSWD_SECRET)
fi

sed -e "s/{{ DB_HOST }}/$DB_HOST/" \
    -e "s/{{ DB_NAME }}/$DB_NAME/" \
    -e "s/{{ DB_PASS }}/$DB_PASS/" \
    -e "s/{{ DB_PORT }}/$DB_PORT/" \
    -e "s/{{ DB_USER }}/$DB_USER/" \
    /var/www/nagiosql/config/settings.php.j2 > /var/www/nagiosql/config/settings.php
if [ -s $NAGIOS_ETC/nagios.cfg ]; then
  sed -i -e "s:use_timezone=UTC:use_timezone=$TZ:" $NAGIOS_ETC/nagios.cfg
else
  echo File $NAGIOS_ETC/nagios.cfg not found, have you mounted volume from jasonrivers/nagios?
  exit 1
fi

for dir in backup/hosts backup/services hosts services; do
  mkdir -p $NAGIOS_OBJ/$dir
done
[ -e /etc/nagiosql ] || ln -s $NAGIOS_OBJ /etc/nagiosql
[ -e /usr/local/nagios ] || ln -s /opt/nagios /usr/local
for file in contactgroups contacttemplates hostdependencies hostescalations \
      hostextinfo hostgroups hosttemplates servicedependencies \
      serviceescalations serviceextinfo servicetemplates timeperiods; do
  if ! grep -q $file.cfg $NAGIOS_ETC/nagios.cfg; then
    echo cfg_file=$NAGIOS_OBJ/$file.cfg >> $NAGIOS_ETC/nagios.cfg
  fi
done
for dir in hosts services; do
  if ! grep -q $NAGIOS_OBJ/$dir $NAGIOS_ETC/nagios.cfg; then
    echo cfg_dir=$NAGIOS_OBJ/$dir >> $NAGIOS_ETC/nagios.cfg
  fi
done
if ! grep -q '^$USER2' $NAGIOS_ETC/resource.cfg; then
  echo '$USER2$=/opt/nagios/plugins' >> $NAGIOS_ETC/resource.cfg
fi
echo '# Removed to avoid conflict with NagiosQL' > $NAGIOS_OBJ/localhost.cfg
echo '# Removed to avoid conflict with NagiosQL' > $NAGIOS_OBJ/templates.cfg

chown -R $APACHE_USER $NAGIOS_OBJ \
  /var/www/nagiosql/config/settings.php

[ -x /etc/apache2/envvars ] && . /etc/apache2/envvars
exec /usr/sbin/$APACHE_BIN -D FOREGROUND
