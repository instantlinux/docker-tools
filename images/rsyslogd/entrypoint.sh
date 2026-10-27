#!/bin/sh

( while true; do sleep 86400
  logrotate --state /tmp/logrotate.state /etc/logrotate.d/syslog; done ) &
rsyslogd -v
exec rsyslogd -n -i /tmp/rsyslogd.pid
