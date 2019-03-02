FROM python:3.7.2-slim-stretch
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mariadb-galera \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    CLUSTER_NAME=cluster01 \
    CLUSTER_SIZE=3 \
    DISCOVERY_SERVICE=etcd:2379 \
    ROOT_PASSWORD_SECRET=mysql-root-password \
    TTL=10 \
    TZ=UTC \
    SST_AUTH_SECRET=sst-auth-password

ARG MARIADB_MAJOR=10.3
ARG MARIADB_VERSION=10.3.13
ARG APT_KEY=F1656F24C74CD1D8
ARG DEB_REL=stretch
ARG UID=212
ARG GID=212

COPY requirements/ /root/

RUN apt-get -yq update && apt-get install -yq gnupg && \
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $APT_KEY && \
    echo "deb [arch=amd64] \
     http://nyc2.mirrors.digitalocean.com/mariadb/repo/$MARIADB_MAJOR/debian $DEB_REL main" \
     > /etc/apt/sources.list.d/mariadb.list && \
    groupadd -g $GID mysql && \
    useradd -u $UID -g $GID -s /bin/false -c "MariaDB" -d /none mysql && \
    apt-get -yq update && apt-get -yq install --no-install-recommends \
     curl iputils-ping jq mariadb-server=1:$MARIADB_VERSION+maria~$DEB_REL \
     mariadb-backup=1:$MARIADB_MAJOR_$MARIADB_VERSION+maria~$DEB_REL \
     mariadb-client=1:$MARIADB_MAJOR_$MARIADB_VERSION+maria~$DEB_REL \
     net-tools netcat procps && \
    pip install -r /root/common.txt && \
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure dash || true && \
    apt-get clean && rm -fr /var/log/* /var/lib/mysql/* && \
    rm -fr /root/.cache /usr/share/zoneinfo/leap-seconds.list

EXPOSE 3306 4444 4567/udp 4567 4568
VOLUME /var/lib/mysql

HEALTHCHECK --interval=10s --timeout=3s --retries=30 \
    CMD /bin/sh /usr/local/bin/healthcheck.sh || exit 1

COPY --chown=root my.cnf /etc/mysql/
COPY --chown=root wsrep.cnf /etc/
COPY --chown=root src/entrypoint.py src/healthcheck.sh /usr/local/bin/
RUN chmod o-w /etc/mysql/my.cnf /etc/wsrep.cnf /usr/local/bin/entrypoint.py
ENTRYPOINT ["/usr/local/bin/entrypoint.py"]

# TODO: fix healthcheck.sh to handle long-duration bootstrap
