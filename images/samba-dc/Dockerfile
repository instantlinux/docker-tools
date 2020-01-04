FROM alpine:3.11
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
    WORKGROUP=WORKGROUP

ARG BIND9_VER=9.15.7
ARG BIND9_SHA=99ec7779c0a48a381338dde7e778d499ba677ea031823683004abc3c369898e3
ARG SAMBA_VERSION=4.11.4-r1

COPY *.conf.j2 /root/
COPY entrypoint.sh /usr/local/bin/

# The bind-tools package on Alpine omits gssapi, so build it here.
# Refer to compile options at:
#  https://git.alpinelinux.org/cgit/aports/tree/main/bind/APKBUILD
RUN apk add --update --no-cache krb5 ldb-tools samba-dc=$SAMBA_VERSION tdb \
      bind-libs libcrypto1.1 libxml2 && \
    apk add --virtual .fetch-deps curl file gcc krb5-dev libcap-dev \
      libgss-dev libuv-dev libxml2-dev linux-headers make musl-dev \
      openssl-dev perl && \
    cd /tmp && \
    curl -Lo bind.tar.xz \
      ftp://ftp.isc.org/isc/bind9/$BIND9_VER/bind-$BIND9_VER.tar.xz && \
    echo "$BIND9_SHA  bind.tar.xz" > checksums && \
    sha256sum -c checksums && \
    tar xf bind.tar.xz --strip-components=1 && \
    CFLAGS=-O2 ./configure --with-gssapi=/usr/include/gssapi --with-dlopen=yes \
      --prefix=/usr --sysconfdir=/etc/bind --localstatedir=/var \
      --with-openssl=/usr --enable-linux-caps --with-libxml2 \
      --enable-shared --with-libtool --without-python && \
    make && \
    for TARGET in lib bin/delv bin/dig bin/dnssec bin/nsupdate; do \
      make -C $TARGET install; \
    done && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /tmp/* && \
    chmod 0755 /usr/local/bin/entrypoint.sh

VOLUME /etc/samba /var/lib/samba
EXPOSE 53 53/udp 88 88/udp 135 137-138/udp 139 389 389/udp 445 464 464/udp 636 3268-3269 49152-65535

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
