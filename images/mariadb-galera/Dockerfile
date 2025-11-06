FROM mariadb:12.0.2
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mariadb-galera \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    CLUSTER_NAME=cluster01 \
    CLUSTER_SIZE=3 \
    DISCOVERY_SERVICE=etcd:2379 \
    ROOT_SECNAME=mysql-root-password \
    TTL=10 \
    TZ=UTC
ARG UID=212
ARG GID=212

COPY requirements/ /root/
RUN groupmod -g $GID mysql && \
    usermod -u $UID -s /bin/false -c "MariaDB" -d /none mysql && \
    apt -yq update && apt -yq install --no-install-recommends \
     curl iputils-ping jq net-tools netcat-openbsd procps \
     python3 python3-pip python3-etcd3 && \
    apt-get clean && rm -fr /var/log/* /var/lib/mysql/* \
      /var/lib/apt/lists /var/cache/debconf/*old /root/.cache
RUN pip install -r /root/common.txt --break-system-packages && \
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure dash || true

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
