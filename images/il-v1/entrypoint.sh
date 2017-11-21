#!/bin/bash -e
DIR=/var/www/htdocs/il
PHPINI=/etc/php5/php.ini
DB_PASSWORD=$(cat /run/secrets/$DB_PASSWD_SECRET)
ILCLIENT_PASSWD=$(cat /run/secrets/$SECRET_ILCLIENT_PASSWORD)
ILINUX_PASSWD=$(cat /run/secrets/$SECRET_ILINUX_PASSWORD)
BKP_PASSWD=$(cat /run/secrets/$SECRET_MYSQL_BACKUP)

cp /run/secrets/$SECRET_SSH_CAPI /run/secrets/$SECRET_SSH_PROXY /run/
chmod 400 /run/$SECRET_SSH_CAPI /run/$SECRET_SSH_PROXY
mkdir -m 700 -p /home/capi/.ssh/proxies
chown -R capi /home/capi/.ssh /run/$SECRET_SSH_CAPI /run/$SECRET_SSH_PROXY
ln -s /run/$SECRET_SSH_CAPI /home/capi/.ssh/id_rsa
ln -s /run/$SECRET_SSH_PROXY /home/capi/.ssh/proxies/scope-1-primary-dsa

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

mkdir -p $DIR/app/views/themed/ilinux/layouts/json \
      $DIR/app/tmp/cache/{models,persistent} \
      $DIR/app/tmp/logs /etc/default /var/log/ilinux
chown -R apache $DIR/app/tmp

for file in $DIR/app/config/database.php \
            /etc/apache2/conf.d/vhost-il.conf \
            /etc/php5/php.ini; do
  sed -e "s/{{ DB_HOST }}/$DB_HOST/" \
      -e "s/{{ DB_NAME }}/$DB_NAME/" \
      -e "s/{{ DB_PASSWORD }}/$DB_PASSWORD/" \
      -e "s/{{ DB_USER }}/$DB_USER/" \
      -e "s:{{ DOC_ROOT }}:$DIR:" \
      -e "s/{{ FQDN }}/$FQDN/" \
      -e "s:{{ TZ }}:$TZ:" \
      /root/src/$(basename $file).j2 > ${file}
done
cd $DIR/app
for file in config/core.php-1.3.7 \
            views/themed/ilinux/layouts/theme-ilinux-default.ctp \
            /etc/default/secure.sh \
            /etc/default/source.sh \
            /var/lib/ilinux/actions/capfile; do
  sed -e 's/ -%>/ %>/g' -e "s/cache_servers.join(\"','\")/cache_server/g" \
      /root/src/$(basename $file).erb | \
    erb acl_classname=DbAcl \
      acl_database=default \
      arch_dir=/var/run/ilinux/arch \
      cache_check=true \
      cache_duration=3600 \
      cache_short=60 \
      cache_engine=Memcache \
      cache_server=127.0.0.1:11211 \
      capfile_dir=/var/lib/ilinux/actions \
      capfile_owner=capi \
      cron_dir=/var/lib/ilinux/cron \
      debug_level=1 \
      fqdn=$FQDN \
      ilclient_passwd=$ILCLIENT_PASSWD \
      ilinux_passwd=$ILINUX_PASSWD \
      log_dir=/var/log/ilinux \
      log_level=true \
      log_syslog_disabled=true \
      log_syslog_facility=local1 \
      mysql_bkppw=$MYSQL_BKPPW \
      rest_url=https://$FQDN \
      security_cipherseed=76563959497453542496749683645 \
      security_level=low \
      security_salt= \
      session_cookie=ILSES \
      session_timeout=120 \
      theme=ilinux \
      url_prefix= \
    > ${file}
done
ln -fns core.php-1.3.7 config/core.php
ln -fs theme-ilinux-default.ctp views/themed/ilinux/layouts/default.ctp
ln -s ../../svn/libs/common.php ./libs
chmod -R g+rX,o+rX .
chown capi /var/lib/ilinux/actions/capfile
chown root.care /etc/default/secure.sh
chmod 440 /etc/default/secure.sh
chown capi.logs /var/log/ilinux /var/run/ilinux/arch
chmod 2770 /var/log/ilinux
chmod 2750 /var/run/ilinux/arch
mkdir -p /run/apache2 /run/memcached
chown memcached /run/memcached
memcached -d -p 11211 -u memcached -m 64 -c 1024 -P /run/memcached/memcached.pid

for host in $REMOTES; do
  su capi -c "ssh-keyscan $host >> /home/capi/.ssh/known_hosts"
done
chown capi /var/run/ilinux/arch

cat <<EOF >/etc/apache2/conf.d/enmod.conf
LoadModule deflate_module modules/mod_deflate.so
LoadModule expires_module modules/mod_expires.so
LoadModule rewrite_module modules/mod_rewrite.so
EOF
/usr/sbin/httpd -DFOREGROUND
