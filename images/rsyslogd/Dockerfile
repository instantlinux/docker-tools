FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=rsyslogd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG RSYSLOG_VERSION=8.40.0-r3
ENV TZ=UTC
RUN apk add --update gzip logrotate rsyslog=$RSYSLOG_VERSION \
      rsyslog-mysql=$RSYSLOG_VERSION tar xz && \
    rm -fr /var/log/* /var/cache/apk/*

VOLUME /var/log /etc/logrotate.d /etc/rsyslog.d
EXPOSE 514 514/udp
COPY logrotate.conf /etc/logrotate.conf

ADD entrypoint.sh /root/
ENTRYPOINT /root/entrypoint.sh
