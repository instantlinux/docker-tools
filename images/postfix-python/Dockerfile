ARG POSTFIX_VERSION=3.3.2-r0

# TODO python3 update

FROM instantlinux/postfix:$POSTFIX_VERSION
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=IPL-1.0 \
    org.label-schema.name=postfix-python \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV BLACKLIST_USER_SECRET=mysql-blacklist-user \
    CIDR_MIN_SIZE=32 \
    DB_HOST=dbhost \
    DB_NAME=blacklist \
    DB_USER=blacklister \
    HONEYPOT_ADDRS=honey@mydomain.com \
    INBOUND_RELAY="by mail.mydomain.com" \
    SPAMLIMIT=12 \
    SPAMC_HOST=spamassassin

ARG GETPIP_SHA=dc84268cc3271fc05d0638dc8a50e49a1450c73abbf67cb12ff1dc1e1a9b3a66
ARG GETPIP_URI=https://bootstrap.pypa.io/3.3/get-pip.py
ARG PYTHON_PIP_VERSION=19.0.3

COPY requirements/ /root/
COPY src/ /usr/local/bin/

RUN apk add --no-cache --update \
     curl openssl python2 python2-dev py-configobj py-mysqldb  && \
    mkdir build && cd build && \
    wget -q -O get-pip.py $GETPIP_URI && \
    echo "$GETPIP_SHA  get-pip.py" | sha256sum -c && \
    python get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION && \
    pip --version && \
    apk add --no-cache --virtual .fetch-deps \
      gcc git freetype-dev jpeg-dev musl-dev zlib-dev && \
    pip install -r /root/common.txt && \
    chmod -R g+rx,o+rx /usr/local/bin && \
    adduser -S -u 2026 -g "Spamassassin" -s /bin/sh spamfilter && \
    addgroup spamfilter postdrop && \
    apk del .fetch-deps && \
    find /usr/local -depth \( \
        \( -type d -a -name test -o -name tests \) -o \
        \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
      \) -exec rm -rf '{}' +; \
    rm -fr /var/log/* /var/cache/apk/* /build
