FROM alpine:3.16
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=samba-dc \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ADMIN_PASSWORD_SECRET=samba-admin-password \
    ALLOW_DNS_UPDATES=secure \
    BIND_INTERFACES_ONLY=yes \
    DOMAIN_ACTION=provision \
    DOMAIN_LOGONS=yes \
    DOMAIN_MASTER=no \
    INTERFACES="lo eth0" \
    LOG_LEVEL=1 \
    MODEL=standard \
    NETBIOS_NAME= \
    REALM=ad.example.com \
    SERVER_STRING="Samba Domain Controller" \
    TZ=UTC \
    WINBIND_USE_DEFAULT_DOMAIN=yes \
    WORKGROUP=AD

ARG SAMBA_VERSION=4.16.7-r0

COPY *.conf.j2 /root/
COPY entrypoint.sh /usr/local/bin/
RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' \
      >>/etc/apk/repositories && \
    apk add --update --no-cache krb5 ldb-tools samba-dc@edge=$SAMBA_VERSION \
      samba-libs@edge libwbclient@edge samba-client-libs@edge \
      samba-server-libs@edge samba-libs-py3@edge libsmbclient@edge \
      ldb@edge py3-ldb@edge tdb \
      bind bind-libs bind-tools libcrypto1.1 libxml2 tzdata && \
    chmod 0755 /usr/local/bin/entrypoint.sh

VOLUME /etc/samba /var/lib/samba
EXPOSE 53 53/udp 88 88/udp 135 137-138/udp 139 389 389/udp 445 464 464/udp 636 3268-3269 49152-65535

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
