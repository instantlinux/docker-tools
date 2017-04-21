FROM debian:wheezy
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive \
    SYNC_ROLE=primary \
    SYNC_SSHKEY= \
    SYNC_INTERVAL=5 \
    SECRET=swarm-sync_sshkey \
    TZ=US/Pacific

RUN apt-get -yq update && \
    apt-get install -yq --no-install-recommends unison openssh-server cron && \
    rm -fr /var/cache/debconf /var/lib/apt/lists/* /var/log/* && \
    mkdir /var/log/unison /root/.unison
USER root
EXPOSE 22

COPY src/ /root/src/
VOLUME ["/var/swarm-sync", "/root/.unison", "/var/log/unison"]
ENTRYPOINT ["/root/src/entrypoint.sh"]
