FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=rsyslogd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG RSYSLOG_VERSION=8.2410.0-r1
ENV TZ=UTC
RUN apk add --update gzip logrotate rsyslog=$RSYSLOG_VERSION \
      rsyslog-mysql=$RSYSLOG_VERSION tar xz && \
    rm -fr /var/log/* /var/cache/apk/*
VOLUME /var/log /etc/logrotate.d /etc/rsyslog.d
EXPOSE 514 514/udp
COPY logrotate.conf /etc/logrotate.conf
COPY rsyslog-rotate /etc/logrotate.d/rsyslog

RUN chmod 644 /etc/logrotate.conf

ADD entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
