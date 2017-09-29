#! /bin/sh -e

CONF=/usr/local/lib/udp.conf

SELF_IP=$(ifconfig $INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
if [ "$PORT_LISTEN" == self ]; then
  PORT_LISTEN=$SELF_IP
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
    listen $PORT_LISTEN udp;
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
exec /usr/sbin/nginx
