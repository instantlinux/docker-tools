#!/bin/sh

sed -i -e 's/^module[(]load="imklog"/# module(load="imklog"/' \
    -e 's/^module[(]load="immark"/# module(load="immark"/' \
    /etc/rsyslog.conf
chmod 644 /etc/rsyslog.conf

crond
rsyslogd
touch /var/log/cron && tail -f /var/log/cron
