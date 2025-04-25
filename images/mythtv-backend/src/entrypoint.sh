#! /bin/bash -e
[ -z "$LOCALHOSTNAME" ] && LOCALHOSTNAME=$HOSTNAME
MYTHHOME=/home/mythtv
OSTYPE=`grep ^ID= /etc/os-release|cut -f 2 -d=`

localedef -i $(cut -d. -f1 <<< $LANGUAGE) -f $(cut -d. -f2 <<< $LANGUAGE) $LANG

# TODO - clean out dangling references to apache2, which is no longer used

if [ "$OSTYPE" == "opensuse" ]; then
  ln -fns /usr/share/zoneinfo/$TZ /etc/localtime
  CONF_DIR=/etc/apache2/conf.d
elif [ "$OSTYPE" == "ubuntu" ]; then
  if [[ $(cat /etc/timezone) != $TZ ]]; then
    echo $TZ > /etc/timezone
    DIR=/etc/php/$(php -v|grep PHP | grep -oP "\\d+\.\\d+" | head -1)
    echo "date.timezone = $TZ" > $DIR/apache2/conf.d/50-tz.ini
    echo "date.timezone = $TZ" > $DIR/cli/conf.d/50-tz.ini
    dpkg-reconfigure -f noninteractive tzdata
  fi
  CONF_DIR=/etc/apache2/sites-available
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

for retry in $(seq 1 10); do
  su mythtv -c /usr/bin/mythbackend || echo Unexpected exit retry=$retry
  sleep 60
done
