FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV API_USER=upsmon \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    NAME=apc \
    PORT=auto \
    SECRET=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut

RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --update nut@testing

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
