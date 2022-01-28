FROM debian:bullseye-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=spamassassin \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    CRON_HOUR=1 CRON_MINUTE=30 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441

ARG DCC_VERSION=2.3.168
ARG SPAMD_VERSION=3.4.6-1
ARG DCC_SHA=3fc932325b36a46a93258bdaa483d00ee3a826bea1d00de04f6e84cfbea63bc2
ARG SPAMD_UID=2022

RUN apt-get -yq update && \
    apt-get -y --no-install-recommends install \
     ca-certificates cron curl gcc libc6-dev libdbd-mysql-perl \
     libmail-dkim-perl libnet-ident-perl make pyzor razor gpg gpg-agent \
     procps spamassassin=$SPAMD_VERSION && \
     usermod --uid $SPAMD_UID $USERNAME && \
     chsh -s /bin/sh $USERNAME && \
     mv /etc/mail/spamassassin/local.cf /etc/mail/spamassassin/local.cf-dist && \
\
# Distributed Checksum Clearinghouse - requires a source-compile
#  and to uncomment loadplugin from v310.pre
    cd /tmp && \
    curl -sLo dcc.tar.Z https://www.dcc-servers.net/dcc/source/old/dcc-$DCC_VERSION.tar.Z && \
    echo "$DCC_SHA  dcc.tar.Z" > checksums && \
    sha256sum -c checksums && \
    tar xzf dcc.tar.Z && cd /tmp/dcc-$DCC_VERSION && \
    ./configure --bindir=/usr/bin && make install && \
    sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf && \
    sed -i 's/DCCIFD_ENABLE=off/DCCIFD_ENABLE=on/' /var/dcc/dcc_conf && \
    sed -i '/^#\s*loadplugin .\+::DCC/s/^#\s*//g' /etc/spamassassin/v310.pre && \
    apt-get purge -yq binutils cpp-10 libc6-dev libgcc-10-dev \
     linux-libc-dev make && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

COPY entrypoint.sh /root/
VOLUME ["/var/lib/spamassassin", "/var/log"]
EXPOSE 783
ENTRYPOINT ["/root/entrypoint.sh"]
