FROM debian:buster-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mt-daapd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV SERVER_BANNER="Firefly Media on Ubuntu"
ARG DAAPD_VERSION=26.4+dfsg1-1

RUN apt-get -yq update && apt-get install -yq --no-install-recommends \
    forked-daapd=$DAAPD_VERSION avahi-daemon && \
  mkdir /root/.config && chown daapd /root/.config && chmod 755 /root && \
  apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

VOLUME ["/srv/music", "/var/cache/forked-daapd", "/var/log"]
EXPOSE 3689

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
