FROM alpine:3.24
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.opencontainers.image.source=https://github.com/instantlinux/docker-tools \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=ddclient \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DDCLIENT_VERSION=4.0.0-r2
ARG UID=2029

ENV HOST= \
    INTERVAL=3600 \
    IPLOOKUP_URI=http://ipinfo.io/ip \
    SERVER=members.easydns.com \
    SERVICE_TYPE=easydns \
    USER_LOGIN= \
    USER_SECRETNAME=ddclient-user

RUN adduser -D -u $UID -h /var/lib/ddclient -s /sbin/nologin ddclient && \
    apk add -u --no-cache curl ddclient=$DDCLIENT_VERSION && \
    mv /etc/ddclient/ddclient.conf /etc/ddclient/ddclient.conf-dist && \
    mkdir -p /run/ddclient && \
    chown ddclient /etc/ddclient /run/ddclient /var/cache/ddclient

COPY entrypoint.sh /usr/local/bin/
USER $UID
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
