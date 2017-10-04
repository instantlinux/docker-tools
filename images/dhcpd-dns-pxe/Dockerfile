FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV DHCP_BOOT=pxelinux.0 \
    DHCP_ENABLE=yes \
    DHCP_LEASE_PATH=/var/lib/misc \
    DHCP_LEASE_TIME=3600 \
    DHCP_RANGE="" \
    DHCP_SUBNET1=192.168.1.0 \
    DNS_ENABLE=yes \
    DNS_SERVER="" \
    DNS_UPSTREAM=8.8.8.8 \
    DOMAIN=example.com \
    IP_FORWARDING=false \
    LISTEN_ADDRESS= \
    DHCP_NETBIOS_NAME_SERVERS="" \
    NTP_SERVER=0.pool.ntp.org,1.pool.ntp.org \
    PORT_DNSMASQ_DNS=53 \
    SUBNET1_GATEWAY=192.168.1.1 \
    SUBNET1_INTERFACE=eth0 \
    SUBNET1_NETMASK=255.255.255.0 \
    TFTP_ENABLE=yes \
    TFTP_ROOT=/tftpboot/pxelinux \
    TFTP_SERVER=self \
    TZ=UTC

RUN apk add --no-cache --update dhcp==4.3.4-r3 dnsmasq==2.78

EXPOSE 53/udp 67/udp 69/udp
VOLUME $DHCP_LEASE_PATH $TFTP_ROOT /etc/dhcpd.d /etc/dnsmasq.d
COPY entrypoint.sh /usr/local/bin/
COPY src/*.j2 /root/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
