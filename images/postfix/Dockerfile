FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=IPL-1.0 \
    org.label-schema.name=postfix \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools
ARG POSTFIX_VERSION=3.10.2-r0
ENV SASL_SECRETNAME=postfix-sasl-passwd \
    TZ=UTC

RUN apk add --no-cache --update \
      postfix=$POSTFIX_VERSION cyrus-sasl-login rsyslog \
      spamassassin-client tzdata

EXPOSE 25 3525

VOLUME [ "/etc/postfix/postfix.d", "/var/spool/postfix" ]

COPY rsyslog.conf /etc/rsyslog.conf
COPY entrypoint.sh /root

ENTRYPOINT ["/root/entrypoint.sh"]
