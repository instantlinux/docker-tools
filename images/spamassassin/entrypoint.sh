#!/bin/bash
( /usr/bin/sa-update
  sleep 86400
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
