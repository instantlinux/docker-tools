FROM alpine:3.24
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.opencontainers.image.source=https://github.com/instantlinux/docker-tools \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=git-dump \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ENV API_TOK_SECRETNAME= \
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

ARG GIT_VERSION=2.54.0-r0
ARG GID=505
ARG UID=2032

COPY *.sh /usr/local/bin/
RUN apk add -u --no-cache curl git=$GIT_VERSION jq \
      openssh-client supercronic tzdata && \
    apk upgrade libcrypto3 libssl3 && \
    adduser -u $UID -s /bin/sh -g "git backup" -D $USERNAME && \
    addgroup -g $GID $GROUP && addgroup $USERNAME $GROUP && \
    mkdir -p -m 700 /home/$USERNAME/.ssh /etc/default && \
    chown -R $USERNAME /home/$USERNAME/.ssh /etc/default && \
    chmod o+rx,g+rx /usr/local/bin/*.sh

VOLUME /var/backup /var/log
USER $UID:$GROUP
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
