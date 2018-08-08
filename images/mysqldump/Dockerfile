FROM debian:jessie-slim
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=mysqldump \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    HOUR=3 MINUTE=30 \
    KEEP_DAYS=31 \
    LOCK_FOR_BACKUP= \
    SERVERS=dbhost \
    USERNAME=mysqldump \
    TZ=UTC

ARG UID=210
ARG CLIENT_VERSION=5.7

RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8507EFA5 && \
  apt-get -yq update && apt-get install -y --no-install-recommends \
   ca-certificates apt-transport-https && \
  echo 'deb https://repo.percona.com/apt jessie main' > \
   /etc/apt/sources.list.d/percona.list && \
  apt-get -yqq update && \
  apt-get install -yqq percona-xtradb-cluster-client-$CLIENT_VERSION bzip2 cron && \
  useradd -u $UID -g backup -s /bin/bash -c "Mysql backup" \
    -d /home/$USERNAME -m $USERNAME && \
  rm -fr /var/cache/debconf /var/lib/apt/lists/* /var/log/* && \
  touch /home/$USERNAME/.my.cnf

COPY *.sh /usr/local/bin/
RUN chmod g+rx,o+rx /usr/local/bin/*.sh
VOLUME /var/backup /var/log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
