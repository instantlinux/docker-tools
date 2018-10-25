FROM python:3.7.0-alpine3.8
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mariadb-galera \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV CLUSTER_NAME=cluster01 \
    CLUSTER_SIZE=3 \
    DISCOVERY_SERVICE=etcd:2379 \
    ROOT_PASSWORD_SECRET=mysql-root-password \
    TTL=10 \
    TZ=UTC \
    SST_PASSWORD= \
    SST_SECRET=sst-auth-password

ARG MARIADB_MAJOR=10.3
ARG MARIADB_VERSION=10.3.9-r2
ARG UID=212
ARG GID=212

COPY requirements/ /root/

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' \
      >>/etc/apk/repositories && \
    addgroup -g $GID mysql && \
    adduser -u $UID -G mysql -s /bin/false -g "MariaDB" -h /none -D mysql && \
    apk add --update --no-cache \
     curl jq mariadb@edge=$MARIADB_VERSION \
     mariadb-backup@edge=$MARIADB_VERSION \
     mariadb-client@edge=$MARIADB_VERSION net-tools socat && \
    pip install -r /root/common.txt && \
    ln -s /usr/bin/mysqld /usr/sbin && \
    rm -fr /var/log/* /var/lib/mysql/*

EXPOSE 3306 4444 4567/udp 4567 4568
VOLUME /var/lib/mysql

HEALTHCHECK --interval=10s --timeout=3s --retries=30 \
    CMD /bin/sh /usr/local/bin/healthcheck.sh || exit 1

COPY wsrep.cnf my.cnf /etc/
COPY src/entrypoint.py src/healthcheck.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.py"]

# TODO: fix healthcheck.sh to handle long-duration bootstrap
