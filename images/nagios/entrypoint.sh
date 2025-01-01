#! /bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

sed -i -e "s/=nagiosadmin/=$AUTHORIZED_USERS/" /etc/nagios/cgi.cfg
if [ -s /run/secrets/$HTPASSWD_SECRET ]; then
  cp /run/secrets/$HTPASSWD_SECRET /etc/nagios/htpasswd.users
  chown root:www-data /etc/nagios/htpasswd.users
  chmod 640 /etc/nagios/htpasswd.users
fi

sed -i -e "s/server_name .*/server_name $NAGIOS_FQDN;/" \
       -e "s/listen .*/listen $NGINX_PORT;/" \
  /etc/nginx/http.d/nagios.conf

if [ -s /etc/nagios/nagios.cfg.proto ]; then
  # Generate a nagios.cfg
  NAGIOS_CONF=$(mktemp -d)
  mkdir -p $NAGIOS_CONF

  > $NAGIOS_CONF/cfg_files.cfg
  for file in $(find /etc/nagios/objects -maxdepth 1 -name '*.cfg'); do
    echo cfg_file=$file >> $NAGIOS_CONF/cfg_files.cfg
  done  
  for file in $(find /etc/nagios/objects -mindepth 1 -type d -not -name backup); do
    echo cfg_dir=$file >> $NAGIOS_CONF/cfg_files.cfg
  done
  echo "use_timezone=$TZ" > $NAGIOS_CONF/timezone.cfg

  if [ "$PERF_ENABLE" = "yes" ]; then
    cat >$NAGIOS_CONF/perf.cfg <<EOF
host_perfdata_file_mode=w
host_perfdata_file_template=empty
service_perfdata_file=/var/nagios/perfdata.log
service_perfdata_file_mode=a
service_perfdata_file_processing_command=process-service-perfdata
service_perfdata_file_processing_interval=10
service_perfdata_file_template=$LASTSERVICECHECK$||$HOSTNAME$||$SERVICEDESC$||$SERVICEOUTPUT$||$SERVICEPERFDATA$
EOF
    sed -i -e s/process_performance_data=.*/process_performance_data=1/ \
      /etc/nagios/nagios.cfg.proto
  else
    sed -i -e s/process_performance_data=.*/process_performance_data=0/ \
      /etc/nagios/nagios.cfg.proto
  fi      

  if [ ! -s /etc/nagios/nagios.cfg ]; then
    cat /etc/nagios/nagios.cfg.proto $NAGIOS_CONF/*.cfg > /etc/nagios/nagios.cfg
  fi
  rm -r $NAGIOS_CONF
fi

if [ -s /etc/ssmtp/custom.conf ]; then
  ln -s custom.conf /etc/ssmtp/ssmtp.conf
else    
  cat >/etc/ssmtp/ssmtp.conf <<EOF
#
# /etc/ssmtp.conf -- a config file for sSMTP sendmail.
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=postmaster
# The place where the mail goes. The actual machine name is required
# no MX records are consulted. Commonly mailhosts are named mail.domain.com
Mailhub=$(echo $MAIL_RELAY_HOST|tr -d [])
rewriteDomain=<$NAGIOS_FQDN>

FromLineOverride=yes
UseTLS=$MAIL_USE_TLS
UseSTARTTLS=$MAIL_USE_TLS
EOF
  if [ "$MAIL_AUTH_USER" != "" ]; then
    cat >>/etc/ssmtp/ssmtp.conf <<EOF
AuthMethod=LOGIN
AuthPass=$(cat /run/secrets/$MAIL_AUTH_SECRET)
AuthUser=$MAIL_AUTH_USER
EOF
  fi
fi
chown root:nagios /etc/ssmtp/ssmtp.conf
chmod 640 /etc/ssmtp/ssmtp.conf

# Check configuration for errors
[ "$CONFIG_CHECK" == "yes" ] && /usr/sbin/nagios -v /etc/nagios/nagios.cfg

mkdir -m 700 -p /run/nginx
rm -f /run/fcgiwrap/fcgiwrap.sock
for item in backup hosts services; do
  mkdir -m 755 -p /etc/nagios/objects/$item
done
start-stop-daemon -u nginx -b --exec /usr/bin/fcgiwrap -- \
  -s unix:/run/fcgiwrap/fcgiwrap.sock
/usr/sbin/php-fpm82
/usr/sbin/nginx
touch /var/nagios/nagios.log && tail -1 -f /var/nagios/nagios.log &
find /var/nagios -not -user nagios -exec chown nagios:nagios {} \;
find /etc/nagios/objects -not -user www-data -exec chown www-data:nagios {} \;

exec /usr/sbin/nagios /etc/nagios/nagios.cfg
