FROM debian:jessie-slim
MAINTAINER Rich Braun <docker@instantlinux.net>

ENV SERVER_BANNER="Firefly Media on Ubuntu"
RUN apt-get -yq update && apt-get install -yq --no-install-recommends \
    forked-daapd avahi-daemon && \
  apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

VOLUME ["/srv/music", "/var/cache/forked-daapd", "/var/log"]
EXPOSE 3689

ADD entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
