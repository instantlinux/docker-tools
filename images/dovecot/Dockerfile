FROM instantlinux/postfix:3.8.3-r1

MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dovecot \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DOVECOT_VERSION=2.3.21-r17
ARG MKCERT_SHA=24b6988d1709e71c24dcf94ffce5db93bd2e89dc5cbec1ac3c173de5274b68dd

ENV LDAP_PASSWD_SECRET=ldap-ro-password \
    SSL_DH=

# TODO - procmail is missing from 3.12 repo, unsure if support ended
RUN echo '@old http://dl-cdn.alpinelinux.org/alpine/v3.11/main' \
      >>/etc/apk/repositories && \
    apk add --no-cache dovecot=$DOVECOT_VERSION dovecot-ldap=$DOVECOT_VERSION \
      procmail@old && \
    rm /etc/ssl/dovecot/server.* && cd /usr/local/bin && \
    wget -q https://raw.githubusercontent.com/dovecot/core/release-2.3.21/doc/mkcert.sh && \
    echo "$MKCERT_SHA  mkcert.sh" | sha256sum -c && \
    chmod 755 /usr/local/bin/mkcert.sh
    
EXPOSE 143 993 
VOLUME /etc/dovecot/conf.local /home /var/spool/mail

COPY entrypoint-dovecot.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint-dovecot.sh"]
