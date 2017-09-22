FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV DHCP_BOOT=pxelinux.0 \
    DHCP_ENABLE=yes \
    DHCP_RANGE=192.168.1.101,192.168.1.150 \
    DNS_ENABLE=yes \
    DNS_SERVER="" \
    DOMAIN=example.com \
    IP_FORWARDING=0 \
    NTP_SERVER=0.pool.ntp.org,1.pool.ntp.org \
    SUBNET1_GATEWAY=192.168.1.1 \
    SUBNET1_INTERFACE=eth0 \
    SUBNET1_NETMASK=255.255.255.0 \
    TFTP_ENABLE=yes \
    TFTP_ROOT=/tftpboot/pxelinux

RUN apk add --no-cache --update dnsmasq

EXPOSE 53 53/udp 67 67/udp 68/udp 69 69/udp
VOLUME $TFTP_ROOT /etc/dnsmasq.d/local /var/lib/misc
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
