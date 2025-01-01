#!/bin/sh -e

function graceful_stop() {
    echo "Received SIGTERM"
    kill -SIGTERM $(cat /run/keepalived/*.pid)
    sleep 1; exit 0
}

if [ -s /run/secrets/$STATS_SECRETNAME ]; then
  STATS_PASSWORD=$(cat /run/secrets/$STATS_SECRETNAME)
else
  STATS_PASSWORD=changeme
fi
HAPROXY_PATH=/usr/local/etc/haproxy
if [ ! -e $HAPROXY_PATH/haproxy.cfg ]; then
  cat <<EOF >$HAPROXY_PATH/haproxy.cfg
global
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
EOF
  if [ $STATS_ENABLE == yes ]; then
    cat <<EOF >>$HAPROXY_PATH/haproxy.cfg
listen stats
       bind		*:$PORT_HAPROXY_STATS
       mode		http
       stats		enable
       stats		hide-version
       stats auth	$STATS_USER:$STATS_PASSWORD
       stats realm	HAProxy\ Statistics
       stats uri	$STATS_URI
EOF
  fi
fi

if [ -d /usr/local/etc/haproxy.d ] && [ "$(ls -A /usr/local/etc/haproxy.d)" ]; then
  CMD_OPTS="-- /usr/local/etc/haproxy.d/*"
fi

sed -i -e 's/^module[(]load="imklog"/# module(load="imklog"/' \
       -e 's/^module[(]load="immark"/# module(load="immark"/' /etc/rsyslog.conf
if [ ! -e /etc/rsyslog.d/udp.conf ]; then
  mkdir -p /etc/rsyslog.d
  cat <<EOF > /etc/rsyslog.d/udp.conf
module(load="imudp")
\$UDPServerRun 514
\$UDPServerAddress 127.0.0.1
EOF
fi
> /var/log/messages
rm -f /run/rsyslogd.pid && rsyslogd

if ! keepalived -i $KEEPALIVE_CONFIG_ID; then
  echo keepalived did not start, needs working /etc/keepalived/keepalived.conf
fi
trap graceful_stop SIGTERM

sleep 10
haproxy -f $HAPROXY_PATH/haproxy.cfg $CMD_OPTS || true
tail +1 -f /var/log/messages &
wait
