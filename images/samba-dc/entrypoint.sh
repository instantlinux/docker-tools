#!/bin/sh -e

if [ -z "$NETBIOS_NAME" ]; then
  NETBIOS_NAME=$(hostname -s | tr [a-z] [A-Z])
else
  NETBIOS_NAME=$(echo $NETBIOS_NAME | tr [a-z] [A-Z])
fi
REALM=$(echo "$REALM" | tr [a-z] [A-Z])

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  echo 'Set timezone'
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ ! -f /var/lib/samba/registry.tdb ]; then
  if [ ! -f /run/secrets/$ADMIN_PASSWORD_SECRET ]; then
    echo 'Cannot read secret $ADMIN_PASSWORD_SECRET in /run/secrets'
    exit 1
  fi
  ADMIN_PASSWORD=$(cat /run/secrets/$ADMIN_PASSWORD_SECRET)
  if [ "$BIND_INTERFACES_ONLY" == yes ]; then
    INTERFACE_OPTS="--option=\"bind interfaces only=yes\" \
      --option=\"interfaces=$INTERFACES\""
  fi
  if [ $DOMAIN_ACTION == provision ]; then
    PROVISION_OPTS="--server-role=dc --use-rfc2307 --domain=$WORKGROUP \
    --realm=$REALM --adminpass='$ADMIN_PASSWORD'"
  elif [ $DOMAIN_ACTION == join ]; then
    PROVISION_OPTS="$REALM DC -UAdministrator --password='$ADMIN_PASSWORD'"
  else
    echo 'Only provision and join actions are supported.'
    exit 1
  fi

  rm -f /etc/samba/smb.conf /etc/krb5.conf

  # This step is required for INTERFACE_OPTS to work as expected
  echo "samba-tool domain $DOMAIN_ACTION $PROVISION_OPTS $INTERFACE_OPTS \
     --dns-backend=SAMBA_INTERNAL" | sh

  mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo 'root = administrator' > /etc/samba/smbusers
fi
mkdir -p -m 700 /etc/samba/conf.d
for file in /etc/samba/smb.conf /etc/samba/conf.d/netlogon.conf \
      /etc/samba/conf.d/sysvol.conf; do
  jinjanate /root/$(basename $file).j2 -o $file
done
for file in $(ls -A /etc/samba/conf.d/*.conf); do
  echo "include = $file" >> /etc/samba/smb.conf
done
ln -fns /var/lib/samba/private/krb5.conf /etc/
exec samba --model=$MODEL -i </dev/null
