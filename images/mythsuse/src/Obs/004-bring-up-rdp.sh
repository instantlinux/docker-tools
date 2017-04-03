#!/bin/bash
mkdir -p /home/mythtv/
mkdir -p  /var/run/sshd
mkdir  -p /root/.vnc
chown -R mythtv:users /home/mythtv/ /var/log/mythtv
/usr/bin/supervisord -c /root/supervisor-files/rdp-supervisord.conf & >/dev/null 2>&1
