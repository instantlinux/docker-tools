FROM alpine:3.5
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV TZ=US/Pacific
RUN apk add --update gzip logrotate rsyslog rsyslog-mysql tar xz && \
    rm -fr /var/log/* /var/cache/apk/*

VOLUME /var/log /etc/logrotate.d /etc/rsyslog.d
EXPOSE 514 514/udp
COPY logrotate.conf /etc/logrotate.conf

ADD entrypoint.sh /root/
ENTRYPOINT /root/entrypoint.sh
