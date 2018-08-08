FROM debian:stretch-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=blacklist \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    USERNAME=rbldns HOMEDIR=/var/lib/rbldns CFG_NAME=dsbl \
    RBL_DOMAIN=blacklist.mydomain.com \
    NS_SERVERS=127.0.0.1 \
    DB_USER=blacklister \
    DB_NAME=blacklist \
    DB_HOST=dbhost

ARG RBLDNSD_VERSION=0.998b~pre1-1

COPY src/ /root/
RUN apt-get -yq update && \
    apt-get -yq --no-install-recommends install \
      cron curl rbldnsd=$RBLDNSD_VERSION perl libdbd-mysql-perl \
      mariadb-client patch && \
    curl -sL http://www.blue-quartz.com/rbl/rebuild_rbldns.txt > \
      /usr/local/bin/rebuild_rbldns.pl && \
    patch -d /usr/local/bin < /root/rebuild_rbldns.diff && \
    chmod 755 /usr/local/bin/rebuild_rbldns.pl && \
    apt-get purge -yq --auto-remove curl patch && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

VOLUME $HOMEDIR
EXPOSE 53/udp
ENTRYPOINT ["/root/entrypoint.sh"]
