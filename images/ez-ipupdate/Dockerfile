FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=ez-ipupdate \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG EZ_VERSION=3.0.10-r9
ENV HOST= \
    INTERVAL=3600 \
    IPLOOKUP_URI=http://ipinfo.io/ip \
    SERVICE_TYPE=easydns \
    USER_SECRET=ez-ipupdate-user

RUN apk add --update curl ez-ipupdate=$EZ_VERSION && \
    rm -fr /var/log/* /var/cache/apk/*

CMD sh -c 'echo "user=`cat /run/secrets/$USER_SECRET`" > /run/ez.conf && \
    if [ -z "$HOST" ]; then echo "Please set a HOST name"; exit 1; fi && \
    while [ 1 == 1 ]; do \
     IPADDR=`curl -s $IPLOOKUP_URI` && \
     echo "`date --rfc-2822` host=$HOST ipaddr=$IPADDR"; \
     ez-ipupdate -a $IPADDR \
      --host $HOST --service-type $SERVICE_TYPE -c /run/ez.conf ; \
     sleep $INTERVAL; \
    done'

