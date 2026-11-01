FROM debian:trixie-slim
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.opencontainers.image.source=https://github.com/instantlinux/docker-tools \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=blacklist \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    CFG_NAME=dsbl \
    HOMEDIR=/var/lib/rbldns \
    NS_SERVERS=127.0.0.1 \
    RBL_DOMAIN=blacklist.mydomain.com \
    DB_USER=blacklister \
    DB_NAME=blacklist \
    DB_HOST=dbhost \
    TZ=UTC \
    USERNAME=rbldns

ARG RBLDNSD_VERSION=1.0~20210120-3
ARG UID=2035

COPY src/ /opt/blacklist/
RUN apt-get -yq update && apt-get -y upgrade && \
    useradd -u $UID -M -d $HOMEDIR -s /bin/bash $USERNAME && \
    apt-get -yq --no-install-recommends install \
      cron curl rbldnsd=$RBLDNSD_VERSION perl libcap2-bin libdbd-mysql-perl \
      mariadb-client && \
    setcap 'cap_net_bind_service,cap_sys_chroot=+ep' /usr/sbin/rbldnsd && \
    mv /opt/blacklist/rebuild_rbldns.pl /opt/blacklist/entrypoint.sh \
      /usr/local/bin/ && \
    chmod 755 /usr/local/bin/rebuild_rbldns.pl && \
    apt-get purge -yq --auto-remove curl libcap2-bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

VOLUME $HOMEDIR
EXPOSE 53/udp
USER $UID
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
