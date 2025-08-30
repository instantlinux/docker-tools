FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=nut-upsd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ARG NUT_VERSION=2.8.2-r2
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
    SECRETNAME=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=
HEALTHCHECK CMD upsc $NAME@localhost:3493 2>&1|grep -q stale && \
    killall -TERM upsmon || true

RUN apk add --no-cache dash && \
    apk add --update --no-cache nut=$NUT_VERSION \
      busybox tini linux-pam \
      libcrypto3 libssl3 \
      libusb musl net-snmp-libs util-linux

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
