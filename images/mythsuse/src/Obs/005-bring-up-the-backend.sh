#!/bin/bash
echo "Checking whether database(s) are ready"
until [ "$( mysqladmin -u root status 2>&1 >/dev/null | grep -ci error:)" = "0" ]
do
echo "waiting....."
sleep 2s
done
exec /sbin/setuser mythtv /usr/bin/mythbackend --logpath /var/log/mythtv  >/dev/null 2>&1 &
