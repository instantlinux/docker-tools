FROM alpine:3.7
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=IPL-1.0 \
    org.label-schema.name=postfix \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV SASL_PASSWD_SECRET=postfix-sasl-passwd \
    TZ=US/Pacific

RUN apk add --no-cache postfix rsyslog spamassassin-client

EXPOSE 25 3525

VOLUME [ "/etc/postfix/postfix.d", "/var/spool/postfix" ]

COPY rsyslog.conf /etc/rsyslog.conf
COPY entrypoint.sh /root

ENTRYPOINT /root/entrypoint.sh
