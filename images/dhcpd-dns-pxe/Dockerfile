FROM alpine:3.23
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dhcpd-dns-pxe \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ARG KEA_VERSION=3.0.2-r0
ARG DNSMASQ_VERSION=2.91-r0

ENV DB_HOST=db00 \
    DB_NAME=kea \
    DB_USER=kea \
    DB_SECRETNAME=kea-db-password \
    DB_INITIALIZE=yes \
    DHCP_BOOT=pxelinux.0 \
    DHCP_ENABLE=yes \
    DHCP_LEASE_TIME=3600 \
    DHCP_NETBIOS_NAME_SERVERS="" \
    DHCP_SUBNET1=192.168.1.0 \
    DHCP_SUBNET1_POOL="" \
    DNS_ENABLE=yes \
    DNS_SERVER="" \
    DNS_UPSTREAM=8.8.8.8 \
    DOMAIN=example.com \
    IP_FORWARDING=false \
    LISTEN_ADDRESS= \
    MAX_LEASE_TIME=14400 \
    NTP_SERVER=0.pool.ntp.org,1.pool.ntp.org \
    PORT_DNSMASQ_DNS=53 \
    SUBNET1_GATEWAY=192.168.1.1 \
    SUBNET1_INTERFACE=eth0 \
    SUBNET1_NETMASK=255.255.255.0 \
    TFTP_ENABLE=yes \
    TFTP_ROOT=/tftpboot/pxelinux \
    TFTP_SERVER=self \
    TZ=UTC

RUN apk add --no-cache --update kea=$KEA_VERSION dnsmasq=$DNSMASQ_VERSION \
      kea-admin kea-hook-mysql mariadb-client && \
    mkdir -m 755 /run/kea && chown kea /run/kea

EXPOSE 53/udp 67/udp 69/udp 8000/tcp
VOLUME $TFTP_ROOT /etc/dhcpd.d/local /etc/dnsmasq.d/local
COPY entrypoint.sh /usr/local/bin/
COPY src/*.j2 /root/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
