#!/bin/sh
# This is called from the base container's entrypoint.sh
# Adds .my.cnf for spamfilter user

# SYS-337 DNS resolution workaround
if grep -q '^options ndots' /etc/resolv.conf; then
    # cannot edit in-place with sed, resource-busy
    cp /etc/resolv.conf /etc/resolv.conf.new
    sed -i -e 's/^options ndots/#options ndots/' /etc/resolv.conf.new
    cat /etc/resolv.conf.new >/etc/resolv.conf
fi

DB_CFG=/home/spamfilter/.my.cnf
if [ ! -f $DB_CFG ]; then
  cat > $DB_CFG <<EOF
[client]
host=$DB_HOST
database=$DB_NAME
EOF
  cat /run/secrets/$BLACKLIST_USER_SECRETNAME >> $DB_CFG
  cat > /home/spamfilter/.profile <<EOF
export CIDR_MIN_SIZE=$CIDR_MIN_SIZE
export DB_USER=$DB_USER
export HONEYPOT_ADDRS="$HONEYPOT_ADDRS"
export INBOUND_RELAY="$INBOUND_RELAY"
export SPAMC_HOST=$SPAMC_HOST
export SPAMLIMIT=$SPAMLIMIT
EOF
  mkdir -p /var/spool/postfix/quarantine
  chown spamfilter /var/spool/postfix/quarantine
fi

