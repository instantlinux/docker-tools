#! /bin/sh -e

# created 27 sep 2017 by richb
#  Populates kea.conf and defaults in /etc/kea.d & /etc/dnsmasq.d
#  Starts kea dhcpd (optionally) and dnsmasq

DHCP_USER=kea

if [ "$DHCP_ENABLE" == yes ]; then
  if [ ! -z "$NETBIOS_NAME_SERVERS" ]; then
    NETBIOS_OPTION="{\"space\": \"dhcp4\", \"name\": \"netbios-name-servers\", \"code\": 44, \"data\": \"$DHCP_NETBIOS_NAME_SERVERS\"},"
  fi
  if [ ! -z "$DHCP_SUBNET1_POOL" ]; then
    POOL_OPTION="\"pools\": [{\"pool\": \"$DHCP_SUBNET1_POOL\"}],"
  fi
  if [ "$TFTP_SERVER" == self ]; then
    TFTP_SERVER=$(ifconfig $SUBNET1_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
  fi
  [ -d /etc/kea.d ] || mkdir -m 750 /etc/kea.d
  chgrp kea /etc/kea.d
  for file in /etc/kea/kea.conf /etc/kea.d/local.conf /etc/kea.d/subnet.conf /etc/kea.d/apc-rpdu.conf; do
    if [ ! -e $file ]; then
      sed -e "s:{{ DB_HOST }}:$DB_HOST:" \
        -e "s:{{ DB_NAME }}:$DB_NAME:" \
        -e "s:{{ DB_USER }}:$DB_USER:" \
        -e "s:{{ DHCP_BOOT }}:$DHCP_BOOT:" \
        -e "s:{{ DHCP_LEASE_TIME }}:$DHCP_LEASE_TIME:" \
        -e "s:{{ DHCP_NETBIOS_NAME_SERVERS }}:$DHCP_NETBIOS_NAME_SERVERS:" \
        -e "s:{{ DHCP_RANGE }}:$DHCP_RANGE:" \
        -e "s:{{ DHCP_SUBNET1 }}:$DHCP_SUBNET1:" \
        -e "s:{{ DNS_SERVER }}:$DNS_SERVER:" \
        -e "s:{{ DNS_UPSTREAM }}:$DNS_UPSTREAM:" \
        -e "s:{{ DOMAIN }}:$DOMAIN:" \
        -e "s:{{ IP_FORWARDING }}:$IP_FORWARDING:" \
        -e "s:{{ MAX_LEASE_TIME }}:$MAX_LEASE_TIME:" \
        -e "s+{{ NETBIOS_OPTION }}+$NETBIOS_OPTION+" \
        -e "s:{{ NTP_SERVER }}:$NTP_SERVER:" \
        -e "s+{{ POOL_OPTION }}+$POOL_OPTION+" \
        -e "s:{{ SUBNET1_GATEWAY }}:$SUBNET1_GATEWAY:" \
        -e "s:{{ SUBNET1_INTERFACE }}:$SUBNET1_INTERFACE:" \
        -e "s:{{ SUBNET1_NETMASK }}:$SUBNET1_NETMASK:" \
        -e "s:{{ TFTP_ENABLE }}:$TFTP_ENABLE:" \
        -e "s:{{ TFTP_SERVER }}:$TFTP_SERVER:" \
        -e "s:{{ TZ }}:$TZ:" \
      /root/$(basename $file).j2 > $file
    fi
  done
  if [ ! -e /run/secrets/$DB_SECRETNAME ]; then
      echo kea-db-password secret is not set, proceeding without database
  else
    DB_PASS=`cat /run/secrets/$DB_SECRETNAME`
    sed -i -e "s:{{ DB_PASS }}:$DB_PASS:" /etc/kea/kea.conf
    if [ "$DB_INITIALIZE" == yes ]; then
      SCHEMA_EXISTS=$(mariadb -s -N -h $DB_HOST -D $DB_NAME -u $DB_USER \
                    -p"$DB_PASS" -e "SHOW TABLES LIKE 'schema_version';")
      [ -z "$SCHEMA_EXISTS" ] && kea-admin db-init mysql -h $DB_HOST \
                    -n $DB_NAME -u $DB_USER -p "$DB_PASS"
    fi
  fi
  kea-dhcp4 -c /etc/kea/kea.conf &
  # TODO: remove or make work
  # for file in /etc/kea.d/*.conf /etc/kea.d/local/*.conf; do
  #   if ! grep -q "$file" /etc/dhcpd.conf; then
  #     echo "include \"$file\";" >>/etc/dhcpd.conf
  #   fi
  # done
fi

if [ "$TFTP_ENABLE" == yes ]; then
  TFTP_FLAG=--enable-tftp
  mkdir -p $TFTP_ROOT
  echo tftp-root=$TFTP_ROOT > /etc/dnsmasq.d/tftpd.conf
fi

if [ -d /etc/dnsmasq.d/local ] && [ "$(ls -A /etc/dnsmasq.d/local)" ]; then
  cp -a /etc/dnsmasq.d/local/. /etc/dnsmasq.d
fi

if [ "$DNS_ENABLE" == yes ]; then
  if [ ! -e /etc/dnsmasq.d/dns.conf ]; then
    sed -e "s:{{ DNS_UPSTREAM }}:$DNS_UPSTREAM:" \
      -e "s:{{ DOMAIN }}:$DOMAIN:" \
      -e "s:{{ PORT_DNSMASQ_DNS }}:$PORT_DNSMASQ_DNS:" \
    /root/dns.conf.j2 > /etc/dnsmasq.d/dns.conf
  fi
  if [ -s /etc/dnsmasq.d/hosts ]; then
    echo addn-hosts=/etc/dnsmasq.d/hosts > /etc/dnsmasq.d/hosts.conf
  fi
  if [ ! -z "$LISTEN_ADDRESS" ]; then 
    echo listen-address=$LISTEN_ADDRESS > /etc/dnsmasq.d/dns-listen.conf
  fi
else
  echo port=0 > /etc/dnsmasq.d/dns.conf
fi    

exec dnsmasq --keep-in-foreground --log-facility=- $TFTP_FLAG
