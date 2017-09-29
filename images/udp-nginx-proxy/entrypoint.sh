#! /bin/sh -xe

CONF=/usr/local/lib/udp.conf

SELF_IP=$(ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
if [ "$IP_LISTEN" == self ]; then
  if [ -z "$SELF_IP" ]; then
    echo Could not determine IP for interface=$INTERFACE
    exit 1
  fi
  LISTEN=$SELF_IP:$PORT_LISTEN
elif [ ! -z "$IP_LISTEN" ]; then
  LISTEN=$LISTEN_IP:$PORT_LISTEN
else
  LISTEN=$PORT_LISTEN
fi

if [ ! -s /usr/local/lib/udp.conf ]; then
  cat <<EOF > $CONF
stream {
  upstream backends {
EOF
  for BACKEND in $BACKENDS; do
    if [ "$BACKEND" == self ]; then
      BACKEND=$SELF_IP
    fi
    echo "    server $BACKEND:$PORT_BACKEND weight=10;" >> $CONF
  done
  cat <<EOF >> $CONF
  }
  server {
    listen $LISTEN udp;
    proxy_pass backends;
    proxy_responses 1;
    error_log stderr;
  }
}
EOF
fi

if [ ! -e /etc/nginx/.configured ]; then
  cat $CONF >> /etc/nginx/nginx.conf
  touch /etc/nginx/.configured
fi
exec /usr/sbin/nginx -g 'daemon off;'
