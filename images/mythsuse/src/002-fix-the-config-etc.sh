#!/bin/bash

if [ ! -f "/home/mythtv/icons/bomb.png" ]; then
mkdir -p /home/mythtv/icons
cp /root/bomb.png /home/mythtv/icons/bomb.png
else
echo "icon for kill switch is set"
fi
chmod 755 /home/mythtv/icons/bomb.png

if [ -f "/home/mythtv/.mythtv/config.xml" ]; then
echo "default config file(s) appear to be in place"
else
mkdir -p /home/mythtv/.mythtv
cp /root/config.xml /root/.mythtv/config.xml
cp /root/config.xml /usr/share/mythtv/config.xml
cp /root/config.xml /etc/mythtv/config.xml
cp /root/config.xml /home/mythtv/.mythtv/config.xml
fi

if [ -f "/home/mythtv/.Xauthority" ]; then
echo ".Xauthority file appears to in place"
else
touch /home/mythtv/.Xauthority
fi

if [ ! -f "/home/mythtv/Desktop/Kill-Mythtv-Backend.desktop" ]; then
mkdir -p /home/mythtv/Desktop
cp /root/Kill-Mythtv-Backend.desktop /home/mythtv/Desktop/Kill-Mythtv-Backend.desktop
else
echo "kill switch is set"
fi


if [ ! -f "/home/mythtv/Desktop/mythtv-setup.desktop" ]; then
cp /root/mythtv-setup.desktop /home/mythtv/Desktop/mythtv-setup.desktop
else
echo "setup desktop icon is set"
fi
chmod 755 /home/mythtv/Desktop/*.desktop

if [ -d "/var/lib/mythtv/banners" ]; then
echo "mythtv folders appear to be set"
else
mkdir -p /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos
fi

chown -R mythtv:users /var/lib/mythtv/banners  /var/lib/mythtv/coverart  /var/lib/mythtv/db_backups  /var/lib/mythtv/fanart  /var/lib/mythtv/livetv  /var/lib/mythtv/recordings  /var/lib/mythtv/screenshots  /var/lib/mythtv/streaming  /var/lib/mythtv/trailers  /var/lib/mythtv/videos /home/mythtv

