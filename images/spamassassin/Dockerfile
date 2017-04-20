FROM debian:jessie-slim
MAINTAINER Rich Braun <richb@instantlinux.net>

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=US/Pacific \
    CRON_HOUR=1 CRON_MINUTE=30 \
    USERNAME=debian-spamd \
    EXTRA_OPTIONS=--nouser-config \
    PYZOR_SITE=public.pyzor.org:24441 \
    DCC_VERSION=1.3.159

RUN apt-get -yq update && \
    apt-get -y --no-install-recommends install \
     cron curl gcc libc6-dev libdbd-mysql-perl libmail-dkim-perl \
     libnet-ident-perl make pyzor razor spamassassin && \
    mv /etc/mail/spamassassin/local.cf /etc/mail/spamassassin/local.cf-dist

# Distributed Checksum Clearinghouse - requires a source-compile
RUN curl https://www.dcc-servers.net/dcc/source/old/dcc-$DCC_VERSION.tar.Z |\
      tar xzf - -C /tmp && ls -l /tmp &&cd /tmp/dcc-$DCC_VERSION && \
    ./configure --bindir=/usr/bin && make install
    
RUN sed -i 's/^logfile = .*$/logfile = \/dev\/stderr/g' \
     /etc/razor/razor-agent.conf && \
    sed -i 's/DCCIFD_ENABLE=off/DCCIFD_ENABLE=on/' /var/dcc/dcc_conf && \
    apt-get purge -yq binutils cpp cpp-4.9 gcc libc6-dev libgcc-4.9-dev \
     linux-libc-dev make && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/log/*

COPY entrypoint.sh /root/
VOLUME ["/var/lib/spamassassin", "/var/log"]
EXPOSE 783

ENTRYPOINT ["/root/entrypoint.sh"]
