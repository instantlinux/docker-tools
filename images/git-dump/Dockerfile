FROM alpine:3.21
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=git-dump \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ENV API_TOKEN_SECRETNAME= \
    DEST_DIR=/var/backup/git \
    GROUP=care \
    HOUR=0 MINUTE=45 \
    KEEP_DAYS=31 \
    ORG= \
    REPO_PREFIX=git@github.com:instantlinux/ \
    REPOS= \
    SCM_TYPE=github \
    SSHKEY_SECRETNAME=git-dump_sshkey \
    SSH_PORT=22 \
    USERNAME=git-dump \
    TZ=UTC

ARG GIT_VERSION=2.47.2-r0
ARG GID=505
ARG UID=212

COPY *.sh /usr/local/bin/
RUN apk add --no-cache --update curl dcron git=$GIT_VERSION jq \
      openssh-client tzdata && \
    apk upgrade libcrypto3 libssl3 && \
    addgroup -g $GID $GROUP && \
    adduser -u $UID -s /bin/sh -G $GROUP -g "git backup" -D $USERNAME && \
    chmod o+rx,g+rx /usr/local/bin/*.sh

VOLUME /var/backup /var/log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
