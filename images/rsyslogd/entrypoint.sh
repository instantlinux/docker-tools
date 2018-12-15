#!/bin/sh

sed -i -e 's/^$ModLoad imklog/#\$ModLoad imklog/' /etc/rsyslog.conf

crond
rsyslogd
touch /var/log/cron && tail -f /var/log/cron
