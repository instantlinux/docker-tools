#!/bin/sh -xe

PATH=$PATH:/opt/nagios/bin
NAGIOS_DIR=/opt/nagios/etc/objects

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
sed -i -e "s:use_timezone=UTC:use_timezone=$TZ:" /opt/nagios/etc/nagios.cfg

for dir in backup/hosts backup/services hosts services; do
  mkdir -p $NAGIOS_DIR/$dir
done
[ -f /etc/nagiosql] || ln -s $NAGIOS_DIR /etc/nagiosql
[ -f /usr/local/nagios ] || ln -s /opt/nagios /usr/local
for file in contactgroups contacttemplates hostdependencies hostescalations \
      hostextinfo hostgroups hosttemplates servicedependencies \
      serviceescalations serviceextinfo servicetemplates timeperiods; do
  if ! grep -q $file.cfg /opt/nagios/etc/nagios.cfg; then
    echo cfg_file=$NAGIOS_DIR/$file.cfg >> /opt/nagios/etc/nagios.cfg
  fi
done
for dir in hosts services; do
  if ! grep -q $NAGIOS_DIR/$dir /opt/nagios/etc/nagios.cfg; then
    echo cfg_dir=$NAGIOS_DIR/$dir >> /opt/nagios/etc/nagios.cfg
  fi
done
if ! grep -q '^$USER2' /opt/nagios/etc/resource.cfg; then
  echo '$USER2$=/opt/nagios/plugins' >> /opt/nagios/etc/resource.cfg
fi
echo '# Removed to avoid conflict with NagiosQL' > $NAGIOS_DIR/localhost.cfg
echo '# Removed to avoid conflict with NagiosQL' > $NAGIOS_DIR/templates.cfg

chown -R $APACHE_USER $NAGIOS_DIR \
  /var/www/nagiosql/config/settings.php

. /etc/apache2/envvars
exec /usr/sbin/apache2 -D FOREGROUND
