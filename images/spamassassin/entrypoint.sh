#!/bin/bash
# Rules update at startup, then daily at CRON_HOUR:CRON_MINUTE (TZ), with a
# reload of spamd after each successful update
( /usr/bin/sa-update
  while true; do
    now=$(date +%s)
    next=$(date -d "$(printf '%02d:%02d' $((10#$CRON_HOUR)) $((10#$CRON_MINUTE)))" +%s)
    [ "$next" -gt "$now" ] || next=$((next + 86400))
    sleep $((next - now))
    /usr/bin/sa-update && kill -HUP "$(cat /run/spamd/spamd.pid)"
  done
) &

/var/dcc/libexec/dccifd -tREP,20 -tCMN,5, -llog -wwhiteclnt -Uuserdirs \
  -SHELO -Smail_host -SSender -SList-ID

cd /var/lib/spamassassin
mkdir -p .razor .spamassassin .pyzor
razor-admin -discover
razor-admin -create -conf=razor-agent.conf
razor-admin -register -l
echo $PYZOR_SITE > .pyzor/servers
chmod g-rx,o-rx .pyzor .pyzor/servers

exec spamd --allowed-ips=0.0.0.0/0 --helper-home-dir=/var/lib/spamassassin \
   --ip-address --pidfile=/run/spamd/spamd.pid --syslog-socket=none \
   --syslog=stdout --username=$(id -un)  $EXTRA_OPTIONS
