#! /bin/bash
OSTYPE=`grep ^ID= /etc/os-release|cut -f 2 -d=`

localedef -i $(cut -d. -f1 <<< $LANGUAGE) -f $(cut -d. -f2 <<< $LANGUAGE) $LANG

if [ "$OSTYPE" == "opensuse" ]; then
  ln -fns /usr/share/zoneinfo/$TZ /etc/localtime
  DOCUMENT_ROOT=/srv/www/htdocs/mythweb
  CONF_DIR=/etc/apache2/conf.d
elif [ "$OSTYPE" == "ubuntu" ]; then
  if [[ $(cat /etc/timezone) != $TZ ]]; then
    echo "$TZ" > /etc/timezone
    sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/apache2/php.ini
    sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/cli/php.ini
    exec  dpkg-reconfigure -f noninteractive tzdata
  fi
  DOCUMENT_ROOT=/var/www/html/mythweb
  CONF_DIR=/etc/apache2/sites-enabled
fi

if [ -e /run/secrets/mythtv-db-password ]; then
  DBPASSWORD=$(cat /run/secrets/mythtv-db-password)
else
  DBPASSWORD=$(xml_grep --text_only Password /home/mythtv/.mythtv/config.xml)
fi

if [ -e /run/secrets/mythtv-user-password ]; then
  usermod -p $(cat /run/secrets/mythtv-user-password) mythtv
fi

if [ ! -f /home/mythtv/icons/bomb.png ]; then
  mkdir -p /home/mythtv/icons
  cp /root/bomb.png /home/mythtv/icons/bomb.png
  chmod 755 /home/mythtv/icons/bomb.png
fi

if [ ! -f /home/mythtv/.mythtv/config.xml ]; then
  mkdir -p /home/mythtv/.mythtv
  cp /root/config.xml /home/mythtv/.mythtv/config.xml
  chown mythtv /home/mythtv/.mythtv/config.xml
  chmod 600 /home/mythtv/.mythtv/config.xml
fi

if [ ! -f /home/mythtv/Desktop/Kill-Mythtv-Backend.desktop ]; then
  mkdir -p /home/mythtv/Desktop
  cp /root/Kill-Mythtv-Backend.desktop /home/mythtv/Desktop/Kill-Mythtv-Backend.desktop
fi

if [ ! -f /home/mythtv/Desktop/mythtv-setup.desktop ]; then
  cp /root/mythtv-setup.desktop /home/mythtv/Desktop/mythtv-setup.desktop
  chmod 755 /home/mythtv/Desktop/*.desktop
fi

if [ ! -f /home/mythtv/.Xauthority ]; then
  touch /home/mythtv/.Xauthority
  chown mythtv /home/mythtv/.Xauthority
fi

for file in $CONF_DIR/mythweb.conf /home/mythtv/.mythtv/config.xml \
   /etc/apache2/vhosts.d/000-default-myth.conf; do
  sed -i -e "s+{{ APACHE_LOG_DIR }}+$APACHE_LOG_DIR+" \
      -e "s/{{ DBNAME }}/$DBNAME/" \
      -e "s/{{ DBPASSWORD }}/$DBPASSWORD/" \
      -e "s/{{ DBSERVER }}/$DBSERVER/" \
      -e "s+{{ DOCUMENT_ROOT }}+$DOCUMENT_ROOT+" $file
done

if [ ! -f /etc/ssh/ssh_host_rsa_key ] && \
     ! grep -q '^[[:space:]]*HostKey[[:space:]]' /etc/ssh/sshd_config; then
  ssh-keygen -A
fi
/usr/sbin/sshd

if [ -e /etc/apache2/vhosts.d/mythweb.conf ]; then
  mv /etc/apache2/vhosts.d/mythweb.conf /etc/apache2/conf.d/
fi

for mod in deflate filter headers php5 rewrite; do a2enmod $mod; done
apache2ctl start

if [ "$OSTYPE" == "ubuntu" ]; then
  exec /sbin/setuser mythtv /usr/bin/mythbackend
else
  exec su mythtv -c /usr/bin/mythbackend
fi
