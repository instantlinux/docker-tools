FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=nut-upsd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ARG NUT_VERSION=2.8.3-r2
ENV ACTIONS= \
    API_USER=upsmon \
    API_PASSWORD= \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    INSTCMDS= \
    MAXAGE=15 \
    NAME=ups \
    NOTIFYCMD= \
    NUT_DEBUG_LEVEL=0 \
    NUT_QUIET_INIT_SSL=true \
    NUT_QUIET_INIT_UPSNOTIFY=true \
    POLLINTERVAL= \
    PORT=auto \
    SDORDER= \
    SECRETNAME=nut-upsd-password \
    SERIAL= \
    SERVER=primary \
    ULIMIT=2048 \
    USER=nut \
    VENDORID=
HEALTHCHECK CMD upsc $NAME@localhost:3493 2>&1|grep -q stale && \
    killall -TERM upsmon || true

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >>/etc/apk/repositories && \
    apk add --no-cache dash && \
    apk add --update --no-cache nut@edge=$NUT_VERSION \
      busybox curl linux-pam \
      libcrypto3 libssl3 \
      libusb musl net-snmp-libs util-linux

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
