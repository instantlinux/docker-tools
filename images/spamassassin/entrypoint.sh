#!/bin/bash
echo "$CRON_MINUTE $CRON_HOUR * * *   root   sa-update &&\
  kill -HUP \`cat /var/run/spamd.pid\`" > /etc/cron.d/sa-update
cron

/usr/bin/sa-update

mkdir -p /var/run/dcc
/var/dcc/libexec/dccifd -tREP,20 -tCMN,5, -llog -wwhiteclnt -Uuserdirs \
  -SHELO -Smail_host -SSender -SList-ID

chown -R $USERNAME /var/lib/spamassassin
su $USERNAME bash -c "
  cd ~$USERNAME
  mkdir -p .razor .spamassassin .pyzor
  razor-admin -discover
  razor-admin -create -conf=razor-agent.conf
  razor-admin -register -l
  echo $PYZOR_SITE > .pyzor/servers
  chmod g-rx,o-rx .pyzor .pyzor/servers"

cd /var/log
spamd --allowed-ips=0.0.0.0/0 --helper-home-dir=/var/lib/spamassassin \
  --ip-address --pidfile=/var/run/spamd.pid --syslog=file \
  --username=$USERNAME $EXTRA_OPTIONS
touch spamd.log && tail -f spamd.log
