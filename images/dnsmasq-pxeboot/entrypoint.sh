#! /bin/sh

if [ "$DHCP_ENABLE" == yes ]; then
  DHCP_FLAG=--interface=$SUBNET1_INTERFACE
  cat <<EOF >/etc/dnsmasq.d/dhcpd-options.conf
bind-interfaces
dhcp-option=interface:$SUBNET1_INTERFACE,1,$SUBNET1_NETMASK
dhcp-option=interface:$SUBNET1_INTERFACE,3,$SUBNET1_GATEWAY
dhcp-option=15,$DOMAIN
dhcp-option=19,$IP_FORWARDING
dhcp-option=42,$NTP_SERVER
log-dhcp
EOF
  if [ ! -z "$DNS_SERVER" ]; then
    echo dhcp-option=6,$DNS_SERVER >> /etc/dnsmasq.d/dhcpd-options.conf
  fi
  cat <<EOF >/etc/dnsmasq.d/dhcpd-netbios.conf
dhcp-option=46,8   # netbios-node-type
EOF
  if [ ! -z "$DHCP_RANGE" ]; then
    echo "dhcp-range=$DHCP_RANGE" > /etc/dnsmasq.d/dhcp-range.conf
  fi
  if [ -s /etc/dnsmasq.d/local/ethers ]; then
    ln -s /etc/dnsmasq.d/local/ethers /etc/ethers 
    echo read-ethers > /etc/dnsmasq.d/dhcpd-mac-addresses.conf
  fi
  if [ -s /etc/dnsmasq.d/local/dhcpd-options.conf ]; then
    ln -s /etc/dnsmasq.d/local-options.conf
  fi
fi

if [ "$TFTP_ENABLE" == yes ]; then
  TFTP_FLAG=--enable-tftp
  mkdir -p $TFTP_ROOT
  cat <<EOF >/etc/dnsmasq.d/tftpd.conf
dhcp-boot=$DHCP_BOOT
# send disable multicast and broadcast discovery, and to download the boot file
dhcp-option=vendor:PXEClient,6,2b
dhcp-option=210,/tftpboot/pxelinux
tftp-root=$TFTP_ROOT
EOF
fi

if [ "$DNS_ENABLE" == yes ]; then
  cat <<EOF >/etc/dnsmasq.d/dns.conf
addn-hosts=/etc/dnsmasq.d/local/hosts
bogus-priv
domain=$DOMAIN
domain-needed
local=/$DOMAIN/
no-hosts
no-poll
no-resolv
server=8.8.8.8
EOF
else
  echo port=0 > /etc/dnsmasq.d/dns.conf
fi    

exec dnsmasq --no-daemon $TFTP_FLAG $DHCP_FLAG
