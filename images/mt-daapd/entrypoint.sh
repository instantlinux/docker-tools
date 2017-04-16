#!/bin/bash

sed -i -e "s/name = \"My Music on %h\"/name = \"${SERVER_BANNER}\"/" /etc/forked-daapd.conf
chown -R daapd /var/cache/forked-daapd
rm -fr /var/run/dbus ; mkdir -p /var/run/dbus
/usr/bin/dbus-daemon --system
/usr/sbin/avahi-daemon --no-chroot -D
/usr/sbin/forked-daapd -f -c /etc/forked-daapd.conf
