#! /bin/bash -e
[ -z "$LOCALHOSTNAME" ] && LOCALHOSTNAME=$HOSTNAME
MYTHHOME=/home/mythtv
OSTYPE=`grep ^ID= /etc/os-release|cut -f 2 -d=`

localedef -i $(cut -d. -f1 <<< $LANGUAGE) -f $(cut -d. -f2 <<< $LANGUAGE) $LANG

if [ "$OSTYPE" == "opensuse" ]; then
  ln -fns /usr/share/zoneinfo/$TZ /etc/localtime
  CONF_DIR=/etc/apache2/conf.d
  DOCUMENT_ROOT=/srv/www/htdocs/mythweb
elif [ "$OSTYPE" == "ubuntu" ]; then
  if [[ $(cat /etc/timezone) != $TZ ]]; then
    echo $TZ > /etc/timezone
    DIR=/etc/php/$(php -v|grep  PHP | grep -oP "\\d+\.\\d+")
    echo "date.timezone = $TZ" > $DIR/apache2/conf.d/50-tz.ini
    echo "date.timezone = $TZ" > $DIR/cli/conf.d/50-tz.ini
    dpkg-reconfigure -f noninteractive tzdata
  fi
  CONF_DIR=/etc/apache2/sites-available
  DOCUMENT_ROOT=/var/www/html/mythweb
fi

if [ -e /run/secrets/mythtv-db-password ]; then
  DBPASSWORD=$(cat /run/secrets/mythtv-db-password)
fi

if [ -e /run/secrets/mythtv-user-password ]; then
  usermod -p $(cat /run/secrets/mythtv-user-password) mythtv
fi

if [ ! -f $MYTHHOME/.Xauthority ]; then
  touch $MYTHHOME/.Xauthority && chown mythtv $MYTHHOME/.Xauthority
fi

cp /root/config.xml /etc/mythtv/
chmod 600 /etc/mythtv/config.xml && chown mythtv /etc/mythtv/config.xml

for file in $CONF_DIR/mythweb.conf $CONF_DIR/mythweb-settings.conf \
    /etc/mythtv/config.xml; do
  sed -i -e "s+{{ APACHE_LOG_DIR }}+$APACHE_LOG_DIR+" \
      -e "s/{{ DBNAME }}/$DBNAME/" \
      -e "s/{{ DBPASSWORD }}/$DBPASSWORD/" \
      -e "s/{{ DBSERVER }}/$DBSERVER/" \
      -e "s+{{ DOCUMENT_ROOT }}+$DOCUMENT_ROOT+" \
      -e "s/{{ LOCALHOSTNAME }}/$LOCALHOSTNAME/" $file
done

if [ ! -f /etc/ssh/.keys_generated ] && \
     ! grep -q '^[[:space:]]*HostKey[[:space:]]' /etc/ssh/sshd_config; then
  rm /etc/ssh/ssh_host*
  ssh-keygen -A
  touch /etc/ssh/.keys_generated
fi
mkdir -p /var/run/sshd

for mod in deflate filter headers rewrite; do a2enmod $mod; done
a2ensite mythweb mythweb-settings
a2dissite 000-default-mythbuntu
apache2ctl start

for retry in $(seq 1 10); do
  while killall -0 mythtv-setup; do sleep 5; done
  su mythtv -c /usr/bin/mythbackend || echo Unexpected exit retry=$retry
  sleep 60
done
