FROM instantlinux/postfix:latest
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
    SPAMC_HOST=spamc

ARG PYTHON_PIP_VERSION=9.0.1

ADD requirements/ /root/

RUN apk add --no-cache --update \
     curl openssl python2 python2-dev py-configobj py-mysqldb  && \
    mkdir build && cd build && \
    wget -q -O get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION && \
    pip --version && \
    apk add --no-cache --virtual .fetch-deps \
      gcc git freetype-dev jpeg-dev musl-dev zlib-dev && \
    pip install -r /root/common.txt && \
    find /usr/local -depth \( \
        \( -type d -a -name test -o -name tests \) -o \
        \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
      \) -exec rm -rf '{}' +; \
    apk del .fetch-deps; \
    adduser -S -u 2026 -g "Spamassassin filter" -s /bin/sh spamfilter; \
    rm -fr /var/log/* /var/cache/apk/* /build

COPY src/ /usr/local/bin/
