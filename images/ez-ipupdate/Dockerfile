FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV HOST=must_be_set \
    INTERVAL=3600 \
    IPLOOKUP_URI=http://ipinfo.io/ip \
    SERVICE_TYPE=easydns \
    USER_SECRET=ez-ipupdate-user

RUN apk add --update curl ez-ipupdate && \
    rm -fr /var/log/* /var/cache/apk/*

CMD sh -c 'echo "user=`cat /run/secrets/$USER_SECRET`" > /run/ez.conf && \
    while [ 1 == 1 ]; do \
     IPADDR=`curl -s $IPLOOKUP_URI` && \
     echo "`date --rfc-2822` host=$HOST ipaddr=$IPADDR"; \
     ez-ipupdate -a $IPADDR \
      --host $HOST --service-type $SERVICE_TYPE -c /run/ez.conf ; \
     sleep $INTERVAL; \
    done'

