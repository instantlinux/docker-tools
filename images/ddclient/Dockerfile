FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=ddclient \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG DDCLIENT_VERSION=4.0.0-r1
ENV HOST= \
    INTERVAL=3600 \
    IPLOOKUP_URI=http://ipinfo.io/ip \
    SERVER=members.easydns.com \
    SERVICE_TYPE=easydns \
    USER_LOGIN= \
    USER_SECRETNAME=ddclient-user

RUN apk add --no-cache --update curl ddclient=$DDCLIENT_VERSION \
      su-exec && \
    chown ddclient /var/cache/ddclient

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
