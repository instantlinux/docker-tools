FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

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

ARG UID=212
ARG GROUP=care
ARG GID=505

RUN apk add --no-cache --update curl dcron git jq openssh-client && \
    addgroup -g $GID $GROUP && \
    adduser -u $UID -s /bin/sh -G $GROUP -g "git backup" -D $USERNAME

COPY *.sh /usr/local/bin/
VOLUME /var/backup /var/log

ENTRYPOINT /usr/local/bin/entrypoint.sh
