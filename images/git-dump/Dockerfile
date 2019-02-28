FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=git-dump \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV API_TOKEN_SECRET= \
    DEST_DIR=/var/backup/git \
    HOUR=0 MINUTE=45 \
    KEEP_DAYS=31 \
    REPO_PREFIX=git@github.com:instantlinux/ \
    REPOS= \
    SSHKEY_SECRET=git-dump_sshkey \
    SSH_PORT=22 \
    USERNAME=git-dump \
    TZ=UTC

ARG GIT_VERSION=2.20.1-r0
ARG GROUP=care
ARG GID=505
ARG UID=212

COPY *.sh /usr/local/bin/
RUN apk add --no-cache --update curl dcron git=$GIT_VERSION jq openssh-client && \
    addgroup -g $GID $GROUP && \
    adduser -u $UID -s /bin/sh -G $GROUP -g "git backup" -D $USERNAME && \
    chmod o+rx,g+rx /usr/local/bin/*.sh

VOLUME /var/backup /var/log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
