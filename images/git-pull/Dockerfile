FROM alpine:3.5
MAINTAINER Rich Braun <richb@instantlinux.net>

ENV DEST=. \
    GIT_COMMIT=master \
    GIT_HOST=github.com \
    GIT_REPO=uri \
    INTERVAL=0

RUN apk add --update git openssh-client && \
    rm -rf /var/cache/apk/*

VOLUME /git

COPY entrypoint.sh /root/
ENTRYPOINT /root/entrypoint.sh
