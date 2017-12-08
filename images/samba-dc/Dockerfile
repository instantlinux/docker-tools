FROM alpine:3.7
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=samba-dc \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ADMIN_PASSWORD_SECRET=samba-admin-password \
    ALLOW_DNS_UPDATES=disabled \
    BIND_INTERFACES_ONLY=no \
    DOMAIN_ACTION=provision \
    DOMAIN_LOGONS=yes \
    DOMAIN_MASTER=no \
    INTERFACES="lo eth0" \
    LOG_LEVEL=1 \
    MODEL=standard \
    REALM=ad.example.com \
    SERVER_STRING="Samba Domain Controller" \
    TZ=UTC \
    WINBIND_TRUSTED_DOMAINS_ONLY=no \
    WINBIND_USE_DEFAULT_DOMAIN=yes \
    WORKGROUP=WORKGROUP

ARG BIND9_VER=9.11.2
ARG BIND9_SHA=7f46ad8620f7c3b0ac375d7a5211b15677708fda84ce25d7aeb7222fe2e3c77a

RUN apk add --update --no-cache krb5 ldb-tools samba-dc tdb \
      libxml2 libcrypto1.0 && \

# The bind-tools package on Alpine omits gssapi, so build it here.
# Refer to compile options at:
#  https://git.alpinelinux.org/cgit/aports/tree/main/bind/APKBUILD

    apk add --virtual .fetch-deps curl file gcc krb5-dev libgss-dev \
      libxml2-dev linux-headers make musl-dev openssl-dev perl && \
    cd /tmp && \
    curl -Lo bind.tar.gz \
      ftp://ftp.isc.org/isc/bind9/$BIND9_VER/bind-$BIND9_VER.tar.gz && \
    echo "$BIND9_SHA  bind.tar.gz" > checksums && \
    sha256sum -c checksums && \
    tar xf bind.tar.gz --strip-components=1 && \
    CFLAGS=-O2 ./configure --with-gssapi=/usr/include/gssapi --with-dlopen=yes \
      --prefix=/usr --sysconfdir=/etc/bind --localstatedir=/var \
      --with-openssl=/usr --enable-linux-caps --with-libxml2 --enable-threads \
      --enable-filter-aaaa --enable-ipv6 --enable-shared --with-libtool && \
    make && \
    for TARGET in lib bin/delv bin/dig bin/dnssec bin/nsupdate; do \
      make -C $TARGET install; \
    done && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /tmp/*

VOLUME /etc/samba /var/lib/samba
EXPOSE 53 53/udp 88 88/udp 135 137-138/udp 139 389 445 464 464/udp 636 3268-3269

COPY *.conf.j2 /root/
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
