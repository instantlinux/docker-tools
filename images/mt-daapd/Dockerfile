FROM debian:jessie-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mt-daapd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV SERVER_BANNER="Firefly Media on Ubuntu"
RUN apt-get -yq update && apt-get install -yq --no-install-recommends \
    forked-daapd avahi-daemon && \
  apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

VOLUME ["/srv/music", "/var/cache/forked-daapd", "/var/log"]
EXPOSE 3689

ADD entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
