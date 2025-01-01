#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

# SYS-337 DNS resolution workaround
if grep -q '^options ndots' /etc/resolv.conf; then
    # cannot edit in-place with sed, resource-busy
    cp /etc/resolv.conf /etc/resolv.conf.new
    sed -i -e 's/^options ndots/#options ndots/' /etc/resolv.conf.new
    cat /etc/resolv.conf.new >/etc/resolv.conf
fi

mkdir -p -m 700 /var/run/postfix && chown postfix /var/run/postfix
mkdir -p /var/spool/mail && chmod 1777 /var/spool/mail

cd /etc/postfix/postfix.d
if [ -s postfix.cf ]; then
  while read item; do
    echo "$item" | grep -qE "^#.*" && continue
    postconf -e "$item"
  done < postfix.cf
fi
for item in *.map; do
  [ -e $item ] || continue
  cp $item ../`basename $item .map`
  postmap ../`basename $item .map`
done
[ -f master.cf ] && cp master.cf ..
[ -f aliases ] && cp aliases ..
[ -x users.sh ] && ./users.sh
newaliases
cd ..
if [ -s /run/secrets/$SASL_SECRETNAME ]; then
  cp /run/secrets/$SASL_SECRETNAME sasl_passwd
  postmap sasl_passwd
  chmod 600 sasl_passwd*
fi
if [ -x /usr/local/bin/postfix-extras.sh ]; then
  . /usr/local/bin/postfix-extras.sh
fi
meta_directory=/etc/postfix /usr/libexec/postfix/post-install create-missing
# two of the directories aren't set correctly by post-install
chgrp postdrop /var/spool/postfix/maildrop /var/spool/postfix/public
/usr/libexec/postfix/master &
rm -f /var/run/rsyslogd.pid && rsyslogd -n
