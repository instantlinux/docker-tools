FROM instantlinux/postfix:3.10.5-r0

ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dovecot \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DOVECOT_VERSION=2.4.1-r2
ARG PROCMAIL_VERSION=3.22-r4
ARG MKCERT_SHA=d1efad065f9ef34da372847ff4a4d5ffd86b97410b303d8a43ea25aa2119c86d
ARG PROCMAIL_SHA=4ac9f21c3d7dbed5b32e7547da39f4d429de480679b4c856026caea39ca842f9
ARG TARGETARCH
ENV LDAP_SECRETNAME=ldap-ro-password \
    SSL_DH=

RUN cd /tmp && \
    case ${TARGETARCH} in \
    amd64) \
      wget -q https://dl-cdn.alpinelinux.org/alpine/v3.11/main/x86_64/procmail-$PROCMAIL_VERSION.apk && \
      echo "$PROCMAIL_SHA  procmail-$PROCMAIL_VERSION.apk" | sha256sum -c ;; \
    arm64) \
      wget -q https://dl-cdn.alpinelinux.org/alpine/v3.11/main/aarch64/procmail-$PROCMAIL_VERSION.apk ;; \
    arm/v6) \
      wget -q https://dl-cdn.alpinelinux.org/alpine/v3.11/main/armhf/procmail-$PROCMAIL_VERSION.apk ;; \
    arm/v7) \
      wget -q https://dl-cdn.alpinelinux.org/alpine/v3.11/main/armv7/procmail-$PROCMAIL_VERSION.apk ;; \
    esac && \
    apk add --no-cache dovecot=$DOVECOT_VERSION dovecot-ldap=$DOVECOT_VERSION && \
    apk add --allow-untrusted procmail-$PROCMAIL_VERSION.apk && \
    cd /usr/local/bin && \
    wget -q https://raw.githubusercontent.com/dovecot/core/release-2.4.1/doc/mkcert.sh && \
    echo "$MKCERT_SHA  mkcert.sh" | sha256sum -c && \
    rm /tmp/* && chmod 755 /usr/local/bin/mkcert.sh
    
EXPOSE 143 993 
VOLUME /etc/dovecot/conf.local /home /var/spool/mail

COPY entrypoint-dovecot.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint-dovecot.sh"]
