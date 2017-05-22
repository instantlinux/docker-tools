FROM python:2.7.13-slim
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=US/Pacific

ARG MARIADB_VERSION=10.2

RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db && \
    echo "deb [arch=amd64,i386,ppc64el] \
     http://nyc2.mirrors.digitalocean.com/mariadb/repo/$MARIADB_VERSION/debian jessie main" \
     > /etc/apt/sources.list.d/mariadb.list && \
    apt-get -yq update && apt-get -yq install --no-install-recommends \
     curl jq mariadb-server mariadb-client && \
    apt-get clean; rm -fr /var/log/* /var/lib/mysql/*

EXPOSE 3306 4567 4568
VOLUME /var/lib/mysql

COPY bin/ /usr/local/bin/
COPY wsrep.cnf /etc/mysql/
HEALTHCHECK --interval=10s --timeout=3s --retries=15 \
    CMD /bin/sh /usr/local/bin/healthcheck.sh || exit 1
COPY entrypoint.sh my.cnf /root/
ENTRYPOINT /root/entrypoint.sh

#RUN apk add --update bash jq mariadb==$MARIADB_VERSION mariadb-client && \
#    rm -fr /var/log/* /var/cache/apk/*
# TODO: percona-xtrabackup when wsrep_sst_method works in 10.2
