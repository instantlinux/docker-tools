FROM haproxy:3.2.4-alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=haproxy-keepalived \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG KEEPALIVED_VERSION=2.3.1-r0
ENV KEEPALIVE_CONFIG_ID=main \
    PORT_HAPROXY_STATS=8080 \
    STATS_ENABLE=yes \
    STATS_SECRETNAME=haproxy-stats-password \
    STATS_USER=haproxy \
    STATS_URI=/stats \
    TIMEOUT=50000 \
    TZ=UTC

USER root
STOPSIGNAL SIGTERM
RUN apk add --no-cache --update \
      keepalived=$KEEPALIVED_VERSION rsyslog && \
    getent passwd haproxy || adduser -S -u 99 haproxy && \
    adduser -D -s /bin/sh keepalived_script && \
    rm -f /etc/keepalived/keepalived.conf

EXPOSE 8080
VOLUME /usr/local/etc/haproxy.d /etc/keepalived

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD
