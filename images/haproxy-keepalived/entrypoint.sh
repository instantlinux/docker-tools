#!/bin/sh -e

if [ -s /run/secrets/$STATS_SECRET ]; then
  STATS_PASSWORD=$(cat /run/secrets/$STATS_SECRET)
else
  STATS_PASSWORD=changeme
fi

cat <<EOF >/etc/haproxy.cfg
global
	log 127.0.0.1	local0
	log 127.0.0.1	local1 notice
	maxconn		4096
	user		haproxy
	group		haproxy
	daemon

defaults
	log		global
	option		dontlognull
	option		dontlog-normal
	retries		3
	option		redispatch
	maxconn		2000
	timeout connect	5000
	timeout	client	$TIMEOUT
	timeout server	$TIMEOUT

listen stats
       bind		*:8080
       mode		http
       stats		enable
       stats		hide-version
       stats auth	haproxy:$STATS_PASSWORD
       stats realm	HAProxy\ Statistics
       stats uri	/stats
EOF

if [ -d /etc/haproxy.d ] && [ "$(ls -A /etc/haproxy.d)" ]; then
  CMD_OPTS="-- /etc/haproxy.d/*"
fi

sed -i -e 's/^$ModLoad imklog/#\$ModLoad imklog/' \
       -e 's/#$ModLoad imudp/\$ModLoad imudp/' \
       -e 's/#$UDPServerRun 514/\$UDPServerRun 514/' /etc/rsyslog.conf
sed -i -e '/$UDPServerRun 514/a $UDPServerAddress 127.0.0.1' /etc/rsyslog.conf
> /var/log/messages
rm -f /run/rsyslogd.pid && rsyslogd

keepalived -i $KEEPALIVE_CONFIG_ID
sleep 10
haproxy -f /etc/haproxy.cfg $CMD_OPTS || true
tail +1 -f /var/log/messages
