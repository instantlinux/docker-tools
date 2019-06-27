FROM alpine:3.10
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=nut-upsd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG NUT_VERSION=2.7.4-r6
ENV API_USER=upsmon \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    NAME=ups \
    POLLINTERVAL= \
    PORT=auto \
    SECRET=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=

RUN echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --update nut@testing=$NUT_VERSION \
      libcrypto1.1 libssl1.1 net-snmp-libs

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
