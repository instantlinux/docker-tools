#!/bin/bash

sed -i -e "s/name = \"My Music on %h\"/name = \"${SERVER_BANNER}\"/" /etc/forked-daapd.conf
chown -R daapd /var/cache/forked-daapd
mkdir -p /var/run/dbus
[ -e /var/run/dbus/pid ] && rm /var/run/dbus/pid
/usr/bin/dbus-daemon --system
/usr/sbin/avahi-daemon --no-chroot -D
/usr/sbin/forked-daapd -f -c /etc/forked-daapd.conf
