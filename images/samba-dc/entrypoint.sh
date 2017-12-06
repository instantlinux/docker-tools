#!/bin/sh

ADMIN_PASSWORD=$(cat /run/secrets/$ADMIN_PASSWORD_SECRET)
NETBIOS_NAME=$(hostname -s | tr [a-z] [A-Z])

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ ! "$(ls -A /var/lib/samba)" ]; then
  set -x
  if [ "$BIND_INTERFACES_ONLY" == yes ]; then
    INTERFACE_OPTS="--option=\"bind interfaces only=$BIND_INTERFACES_ONLY\" \
      --option=\"interfaces=$INTERFACES\""
  fi
  if [ $DOMAIN_ACTION == provision ]; then
    PROVISION_OPTS="--server-role=dc --use-rfc2307 --domain=$NETBIOS_DOMAIN \
      --adminpass=$ADMIN_PASSWORD"
  else      
    PROVISION_OPTS="$REALM DC -UAdministrator --password=$ADMIN_PASSWORD"
  fi	
  rm -f /etc/samba/smb.conf /etc/krb5.conf
  # TODO: make INTERFACE_OPTS work
  samba-tool domain $DOMAIN_ACTION $PROVISION_OPTS \
    --realm=$REALM --dns-backend=SAMBA_INTERNAL </dev/null

  mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo 'root = administrator' > /etc/samba/smbusers
fi
mkdir -p -m 700 /etc/samba/conf.d
for file in /etc/samba/smb.conf /etc/samba/conf.d/netlogon.conf \
      /etc/samba/conf.d/sysvol.conf; do
  sed -e "s:{{ ALLOW_DNS_UPDATES }}:$ALLOW_DNS_UPDATES:" \
      -e "s:{{ BIND_INTERFACES_ONLY }}:$BIND_INTERFACES_ONLY:" \
      -e "s:{{ DOMAIN_LOGONS }}:$DOMAIN_LOGONS:" \
      -e "s:{{ DOMAIN_MASTER }}:$DOMAIN_MASTER:" \
      -e "s:{{ INTERFACES }}:$INTERFACES:" \
      -e "s:{{ LOG_LEVEL }}:$LOG_LEVEL:" \
      -e "s:{{ NETBIOS_NAME }}:$NETBIOS_NAME:" \
      -e "s:{{ REALM }}:$REALM:" \
      -e "s:{{ SERVER_STRING }}:$SERVER_STRING:" \
      -e "s:{{ WINBIND_TRUSTED_DOMAINS_ONLY }}:$WINBIND_TRUSTED_DOMAINS_ONLY:" \
      -e "s:{{ WINBIND_USE_DEFAULT_DOMAIN }}:$WINBIND_USE_DEFAULT_DOMAIN:" \
      -e "s:{{ WORKGROUP }}:$WORKGROUP:" \
      /root/$(basename $file).j2 > $file
done
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> /etc/samba/smb.conf
done
ln -fns /var/lib/samba/private/krb5.conf /etc/

exec samba --model=$MODEL -i
