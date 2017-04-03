#! /bin/bash
OSTYPE=`grep ^ID= /etc/os-release|cut -f 2 -d=`
[ "$TZ" == "" ] && TZ=UTC
[ "$DBNAME" == "" ] && DBNAME=mythtv

if [ "$OSTYPE" == "opensuse" ]; then
  ln -fns /usr/share/zoneinfo/$TZ /etc/localtime
elif [ "$OSTYPE" == "ubuntu" ]; then
  if [[ $(cat /etc/timezone) != $TZ ]]; then
    echo "$TZ" > /etc/timezone
    sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/apache2/php.ini
    sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/cli/php.ini
    exec  dpkg-reconfigure -f noninteractive tzdata
  fi
fi

bash /root/002-fix-the-config-etc.sh
MYSQLPW=`xml_grep --text_only Password /home/mythtv/.mythtv/config.xml`

if [ "$OSTYPE" == "opensuse" ]; then
  su mythtv -c "/usr/bin/mythbackend --logpath /var/log/mythtv  >/dev/null 2>&1" &
  if [ -e /etc/apache2/vhosts.d/mythweb.conf ]; then
    mv /etc/apache2/vhosts.d/mythweb.conf /etc/apache2/conf.d/
  fi
  sed -i -e "s/DBPASSWORD/$MYSQLPW/" /etc/apache2/conf.d/mythweb.conf
  sed -i -e "s/DBSERVER/$DBSERVER/" /etc/apache2/conf.d/mythweb.conf
  sed -i -e "s/DBNAME/$DBNAME/" /etc/apache2/conf.d/mythweb.conf
elif [ "$OSTYPE" == "ubuntu" ]; then
  exec /sbin/setuser mythtv /usr/bin/mythbackend --logpath /var/log/mythtv  >/dev/null 2>&1 &
  sed -i -e "s/DBPASSWORD/$MYSQLPW/" /etc/apache2/sites-enabled/mythweb.conf
  sed -i -e "s/DBSERVER/$DBSERVER/" /etc/apache2/sites-enabled/mythweb.conf
  sed -i -e "s/DBNAME/$DBNAME/" /etc/apache2/sites-enabled/mythweb.conf
fi
a2enmod php5
a2enmod rewrite 
exec /usr/sbin/apache2ctl -D FOREGROUND >/dev/null 2>&1
tail -f -n1 /etc/resolv.conf
