#! /bin/sh -e

# created 27 sep 2017 by richb
#  Populates dhcpd.conf and defaults in /etc/dhcpd.d & /etc/dnsmasq.d
#  Starts dhcpd (optionally) and dnsmasq

DHCP_USER=dhcp

if [ "$DHCP_ENABLE" == yes ]; then
  if [ ! -z "$NETBIOS_NAME_SERVERS" ]; then
    NETBIOS_OPTION="option netbios-name-servers $DHCP_NETBIOS_NAME_SERVERS;"
  fi
  if [ ! -z "$DHCP_RANGE" ]; then
    RANGE_OPTION="range $DHCP_RANGE;"
  elif [ "$(ls -A /etc/dhcpd.d/ranges)" ]; then
    RANGE=$(cat /etc/dhcpd.d/ranges/$POD_NAME)
    [ -z "$RANGE" ] || RANGE_OPTION="range $RANGE;"
  fi
  if [ "$TFTP_SERVER" == self ]; then
    TFTP_SERVER=$(ifconfig $SUBNET1_INTERFACE | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
  fi
  for file in /etc/dhcpd.conf /etc/dhcpd.d/default.conf /etc/dhcpd.d/subnet.conf /etc/dhcpd.d/apc-rpdu.conf; do
    if [ ! -e $file ]; then
      sed -e "s:{{ DHCP_BOOT }}:$DHCP_BOOT:" \
        -e "s:{{ DHCP_LEASE_TIME }}:$DHCP_LEASE_TIME:" \
        -e "s:{{ DHCP_NETBIOS_NAME_SERVERS }}:$DHCP_NETBIOS_NAME_SERVERS:" \
        -e "s:{{ DHCP_RANGE }}:$DHCP_RANGE:" \
        -e "s:{{ DHCP_SUBNET1 }}:$DHCP_SUBNET1:" \
        -e "s:{{ DNS_SERVER }}:$DNS_SERVER:" \
        -e "s:{{ DNS_UPSTREAM }}:$DNS_UPSTREAM:" \
        -e "s:{{ DOMAIN }}:$DOMAIN:" \
        -e "s:{{ IP_FORWARDING }}:$IP_FORWARDING:" \
        -e "s:{{ MAX_LEASE_TIME }}:$MAX_LEASE_TIME:" \
        -e "s:{{ NETBIOS_OPTION }}:$NETBIOS_OPTION:" \
        -e "s:{{ NTP_SERVER }}:$NTP_SERVER:" \
        -e "s:{{ RANGE_OPTION }}:$RANGE_OPTION:" \
        -e "s:{{ SUBNET1_GATEWAY }}:$SUBNET1_GATEWAY:" \
        -e "s:{{ SUBNET1_NETMASK }}:$SUBNET1_NETMASK:" \
        -e "s:{{ TFTP_ENABLE }}:$TFTP_ENABLE:" \
        -e "s:{{ TFTP_SERVER }}:$TFTP_SERVER:" \
        -e "s:{{ TZ }}:$TZ:" \
      /root/$(basename $file).j2 > $file
    fi
  done
  for file in /etc/dhcpd.d/*.conf /etc/dhcpd.d/local/*.conf; do
    if ! grep -q "$file" /etc/dhcpd.conf; then
      echo "include \"$file\";" >>/etc/dhcpd.conf
    fi
  done
  if [ ! -z "$LISTEN_ADDRESS" ]; then
      LISTEN_FLAG="-s $LISTEN_ADDRESS"
  fi
  touch $DHCP_LEASE_PATH/dhcpd.leases
  chown $DHCP_USER $DHCP_LEASE_PATH/dhcpd.leases
  dhcpd -d -cf /etc/dhcpd.conf -lf $DHCP_LEASE_PATH/dhcpd.leases \
    -user $DHCP_USER -group daemon $LISTEN_FLAG $SUBNET1_INTERFACE &
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
