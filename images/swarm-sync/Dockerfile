FROM debian:wheezy
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive \
    SYNC_ROLE=primary \
    SYNC_SSHKEY= \
    SYNC_INTERVAL=5 \
    TZ=US/Pacific

RUN \
  apt-get -yqq update && \
  apt-get install -yqq unison openssh-server cron
USER root
EXPOSE 22

COPY src/ /root/src/
RUN rm -fr /var/cache/debconf /var/lib/apt/lists/* /var/log/* && \
    mkdir /var/log/unison

VOLUME /var/swarm-sync
VOLUME /var/log/unison

ENTRYPOINT ["/root/src/entrypoint.sh"]
