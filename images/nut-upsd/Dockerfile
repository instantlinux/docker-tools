FROM alpine:3.19
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=nut-upsd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ARG NUT_VERSION=2.8.1-r0
ENV API_USER=upsmon \
    API_PASSWORD= \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    MAXAGE=15 \
    NAME=ups \
    POLLINTERVAL= \
    PORT=auto \
    SDORDER= \
    SECRET=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=
HEALTHCHECK CMD upsc $NAME@localhost:3493 2>&1|grep -q stale && \
    kill -SIGTERM -1 || true

RUN apk add --update nut=$NUT_VERSION \
      libcrypto3 libssl3 libusb musl net-snmp-libs

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
