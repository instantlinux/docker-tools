FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=proftpd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG PROFTPD_VERSION=1.3.6-r7
ENV ALLOW_OVERWRITE=on \
    ANONYMOUS_DISABLE=off \
    ANON_UPLOAD_ENABLE=DenyAll \
    FTPUSER_PASSWORD_SECRET=ftp-user-password-secret \
    FTPUSER_NAME=ftpuser \
    FTPUSER_UID=1001 \
    LOCAL_UMASK=022 \
    MAX_CLIENTS=10 \
    MAX_INSTANCES=30 \
    PASV_ADDRESS= \
    PASV_MAX_PORT=30100 \
    PASV_MIN_PORT=30091 \
    SERVER_NAME=ProFTPD \
    TIMES_GMT=off \
    TZ=UTC \
    WRITE_ENABLE=AllowAll

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' \
      >>/etc/apk/repositories && \
    echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --update libcrypto1.1@edge proftpd@testing=$PROFTPD_VERSION tzdata
COPY proftpd.conf.j2 /etc/proftpd/proftpd.conf

VOLUME /etc/proftpd/conf.d /etc/proftpd/modules.d /var/lib/ftp
EXPOSE 21 $PASV_MIN_PORT-$PASV_MAX_PORT

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
