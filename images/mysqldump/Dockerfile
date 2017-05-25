FROM debian:jessie
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=US/Pacific \
    HOUR=3 MINUTE=30 \
    KEEP_DAYS=31 \
    LOCK_FOR_BACKUP= \
    SERVERS=dbhost

ARG UID=210
ARG USERNAME=mysqldump

RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8507EFA5 && \
  apt-get -yq update && apt-get install -y --no-install-recommends \
   ca-certificates apt-transport-https && \
  echo 'deb https://repo.percona.com/apt jessie main' > \
   /etc/apt/sources.list.d/percona.list && \
  apt-get -yqq update && \
  apt-get install -yqq percona-xtradb-cluster-client-5.7 bzip2 cron && \
  useradd -u $UID -g backup -s /bin/bash -c "Mysql backup" \
    -d /home/$USERNAME -m $USERNAME && \
  rm -fr /var/cache/debconf /var/lib/apt/lists/* /var/log/* && \
  touch /home/$USERNAME/.my.cnf

COPY *.sh /usr/local/bin/
VOLUME /var/backup /var/log

ENTRYPOINT /usr/local/bin/entrypoint.sh
