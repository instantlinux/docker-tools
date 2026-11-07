#!/bin/sh -e

if [ -x /etc/samba/conf.d/users.sh ] && [ ! -f /var/tmp/.users-created ]; then
  /etc/samba/conf.d/users.sh
  touch /var/tmp/.users-created
fi

if [ "$CONFIG_FILE" = /etc/samba/smb.conf ]; then
  sed -e "s:{{ LOGON_DRIVE }}:$LOGON_DRIVE:" \
      -e "s:{{ NETBIOS_NAME }}:$NETBIOS_NAME:" \
      -e "s:{{ SERVER_STRING }}:$SERVER_STRING:" \
      -e "s:{{ WORKGROUP }}:$WORKGROUP:" \
      /opt/samba/smb.conf.j2 > /var/tmp/smb.conf
  if [ $(id -u) = 0 ]; then
    mv /var/tmp/smb.conf $CONFIG_FILE
  else
    CONFIG_FILE=/var/tmp/smb.conf
  fi
fi

mkdir -p /var/lib/samba/usershares
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> $CONFIG_FILE
done

nmbd -D
exec smbd -F --configfile=$CONFIG_FILE --debug-stdout \
  --no-process-group </dev/null
