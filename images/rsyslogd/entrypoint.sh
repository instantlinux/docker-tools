#!/bin/sh

sed -i -e 's/^$ModLoad imklog/#\$ModLoad imklog/' /etc/rsyslog.conf
if [ ! -e /etc/rsyslog.d/00-listener.conf]; then
  cat <<EOF >/etc/rsyslog.d/00-listener.conf
module(load="imudp")       # UDP listener support
module(load="imtcp")       # TCP listener support

input(type="imudp" port="514")
input(type="imtcp" port="514")
EOF
fi

crond
rsyslogd
touch /var/log/cron && tail -f /var/log/cron
