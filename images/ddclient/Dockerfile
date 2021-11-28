FROM alpine:3.15
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=ddclient \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DDCLIENT_VERSION=3.9.1-r1
ENV HOST= \
    INTERVAL=3600 \
    IPLOOKUP_URI=http://ipinfo.io/ip \
    SERVER=members.easydns.com \
    SERVICE_TYPE=easydns \
    USER_LOGIN= \
    USER_SECRET=ddclient-user

RUN echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --no-cache --update curl ddclient@testing=$DDCLIENT_VERSION \
      su-exec && \
    chown ddclient /var/cache/ddclient

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
