FROM alpine:3.5
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV IPLOOKUP_URI=http://ipinfo.io/ip \
    HOST=must_be_set \
    USER_SECRET=ez-ipupdate-user \
    SERVICE_TYPE=easydns \
    INTERVAL=3600

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

