#!/bin/bash
if [[ $(cat /etc/timezone) != $TZ ]] ; then
echo "$TZ" > /etc/timezone
sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/apache2/php.ini
sed -i -e "s#;date.timezone.*#date.timezone = ${TZ}#g" /etc/php/7.0/cli/php.ini
exec  dpkg-reconfigure -f noninteractive tzdata
fi
