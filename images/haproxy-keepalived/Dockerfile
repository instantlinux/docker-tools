FROM haproxy:1.9.1-alpine
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=haproxy-keepalived \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG KEEPALIVED_VERSION=2.0.11-r0
ENV KEEPALIVE_CONFIG_ID=main \
    PORT_HAPROXY_STATS=8080 \
    STATS_ENABLE=yes \
    STATS_SECRET=haproxy-stats-password \
    STATS_URI=/stats \
    TIMEOUT=50000 \
    TZ=UTC

RUN apk add --no-cache --update \
      keepalived=$KEEPALIVED_VERSION rsyslog && \
    adduser -D -s /bin/false haproxy && \
    adduser -D -s /bin/sh keepalived_script && \
    mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.dist

EXPOSE 8080
VOLUME /etc/haproxy.d

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD
