#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -x /etc/samba/conf.d/users.sh ] && [ ! -f /var/tmp/.users-created ]; then
  /etc/samba/conf.d/users.sh
  touch /var/tmp/.users-created
fi

sed -e "s:{{ LOGON_DRIVE }}:$LOGON_DRIVE:" \
    -e "s:{{ NETBIOS_NAME }}:$NETBIOS_NAME:" \
    -e "s:{{ SERVER_STRING }}:$SERVER_STRING:" \
    -e "s:{{ WORKGROUP }}:$WORKGROUP:" \
    /root/smb.conf.j2 > /etc/samba/smb.conf

mkdir -p /var/lib/samba/usershares
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> /etc/samba/smb.conf
done

nmbd -D
exec smbd -F --debug-stdout --no-process-group </dev/null
