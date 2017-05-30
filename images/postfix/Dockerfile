FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV SASL_PASSWD_SECRET=postfix-sasl-passwd \
    TZ=US/Pacific

RUN apk add --no-cache postfix rsyslog spamassassin-client

EXPOSE 25 3525

VOLUME [ "/etc/postfix/postfix.d", "/var/spool/postfix" ]

COPY rsyslog.conf /etc/rsyslog.conf
COPY entrypoint.sh /root

ENTRYPOINT /root/entrypoint.sh
