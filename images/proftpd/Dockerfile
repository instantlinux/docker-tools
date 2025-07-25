FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=proftpd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG PROFTPD_VERSION=1.3.9-r1

ENV ALLOW_OVERWRITE=on \
    ANONYMOUS_DISABLE=off \
    ANON_UPLOAD_ENABLE=DenyAll \
    FTPUSER_NAME=ftpuser \
    FTPUSER_SECRETNAME=ftp-user-password-secret \
    FTPUSER_UID=1001 \
    LOCAL_UMASK=022 \
    MAX_CLIENTS=10 \
    MAX_INSTANCES=30 \
    PASV_ADDRESS= \
    PASV_MAX_PORT=30100 \
    PASV_MIN_PORT=30091 \
    SFTP_ENABLE=off \
    SFTP_PORT=2222 \
    SERVER_NAME=ProFTPD \
    TIMES_GMT=off \
    TZ=UTC \
    WRITE_ENABLE=AllowAll

COPY proftpd.conf.j2 /etc/proftpd/proftpd.conf
RUN chmod 644 /etc/proftpd/proftpd.conf && \
    apk add --update \
        libcrypto3 \
        proftpd=$PROFTPD_VERSION \
        tzdata \
        proftpd-mod_sftp \
        openssh-keygen

VOLUME /etc/proftpd/conf.d /etc/proftpd/modules.d /var/lib/ftp /etc/ssh
EXPOSE 21 $SFTP_PORT $PASV_MIN_PORT-$PASV_MAX_PORT

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
