FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=git-pull \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG GIT_VERSION=2.49.0-r0
ENV DEST=. \
    GIT_COMMIT=master \
    GIT_HOST=github.com \
    GIT_REPO=uri \
    INTERVAL=0

RUN apk add --no-cache --update git=$GIT_VERSION openssh-client && \
    apk upgrade libcrypto3 libssl3
VOLUME /git

COPY entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
