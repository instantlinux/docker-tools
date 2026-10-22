FROM alpine:3.24
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.opencontainers.image.source=https://github.com/instantlinux/docker-tools \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=rest-server \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG REST_SERVER_VERSION=0.14.0-r12
ARG RESTIC_UID=2025
ENV DATA_DIRECTORY=/data \
    PASS_SECNAME=restic-htpasswd

RUN adduser -h /data -s /bin/sbin/nologin -u $RESTIC_UID -D restic && \
    apk add -u --no-cache apache2-utils rest-server=$REST_SERVER_VERSION

VOLUME [/data]
EXPOSE 8000

COPY entrypoint.sh /usr/local/bin/
USER restic
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
