FROM alpine:3.21
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=mysqldump \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV HOUR=3 MINUTE=30 \
    KEEP_DAYS=31 \
    DB_CREDS_SECRETNAME=mysql-backup-creds \
    LOCK_FOR_BACKUP= \
    SERVERS=dbhost \
    SKEW_SECONDS=15 \
    SKIP_SSL=true \
    USERNAME=mysqldump \
    TZ=UTC
ARG UID=210
ARG BACKUP_GID=34
ARG CLIENT_VERSION=11.4.4-r1

RUN RMGROUP=$(grep :$BACKUP_GID: /etc/group | cut -d: -f 1) && \
    [ -z "$RMGROUP" ] || delgroup $RMGROUP && \
    addgroup -g $BACKUP_GID backup && \
    adduser -u $UID -G backup -s /bin/sh -g "MariaDB" -D $USERNAME && \
    apk add --update --no-cache \
     bzip2 dcron mariadb-client=$CLIENT_VERSION tzdata && \
    rm -fr /var/cache/apk/* /var/log/*

COPY *.sh /usr/local/bin/
RUN chmod g+rx,o+rx /usr/local/bin/*.sh
VOLUME /var/backup /var/log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
