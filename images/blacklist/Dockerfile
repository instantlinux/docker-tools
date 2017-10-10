FROM debian:jessie-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=blacklist \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=US/Pacific \
    USERNAME=rbldns HOMEDIR=/var/lib/rbldns CFG_NAME=dsbl \
    RBL_DOMAIN=blacklist.mydomain.com \
    NS_SERVERS=127.0.0.1 \
    DB_USER=blacklister \
    DB_NAME=blacklist \
    DB_HOST=dbhost
    
RUN apt-get -yq update && \
    apt-get -y --no-install-recommends install \
     cron rbldnsd perl libdbd-mysql-perl mariadb-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

COPY src/ /root/src/
VOLUME $HOMEDIR
EXPOSE 53/udp
ENTRYPOINT /root/src/entrypoint.sh
