FROM instantlinux/postfix:3.10.2-r0

ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dovecot \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DOVECOT_VERSION=2.4.1-r2
ARG MKCERT_SHA=d1efad065f9ef34da372847ff4a4d5ffd86b97410b303d8a43ea25aa2119c86d

ENV LDAP_SECRETNAME=ldap-ro-password \
    SSL_DH=

# TODO - procmail is missing from 3.12 repo, unsure if support ended
RUN echo '@old http://dl-cdn.alpinelinux.org/alpine/v3.11/main' \
      >>/etc/apk/repositories && \
    apk add --no-cache dovecot=$DOVECOT_VERSION dovecot-ldap=$DOVECOT_VERSION \
      procmail@old && \
    cd /usr/local/bin && \
    wget -q https://raw.githubusercontent.com/dovecot/core/release-2.4.1/doc/mkcert.sh && \
    echo "$MKCERT_SHA  mkcert.sh" | sha256sum -c && \
    chmod 755 /usr/local/bin/mkcert.sh
    
EXPOSE 143 993 
VOLUME /etc/dovecot/conf.local /home /var/spool/mail

COPY entrypoint-dovecot.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint-dovecot.sh"]
