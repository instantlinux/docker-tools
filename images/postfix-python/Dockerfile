ARG POSTFIX_VERSION=3.10.2-r0

FROM instantlinux/postfix:$POSTFIX_VERSION
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=IPL-1.0 \
    org.label-schema.name=postfix-python \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV BLACKLIST_USER_SECRETNAME=mysql-blacklist-user \
    CIDR_MIN_SIZE=32 \
    DB_HOST=dbhost \
    DB_NAME=blacklist \
    DB_USER=blacklister \
    HONEYPOT_ADDRS=honey@mydomain.com \
    INBOUND_RELAY="by mail.mydomain.com" \
    SPAMLIMIT=12 \
    SPAMC_HOST=spamassassin
ARG GETPIP_SHA=6ed6e98282a504ee0a6632856e16c39f222d313fc38be33de216d4afb6ac12f7
ARG GETPIP_URI=https://bootstrap.pypa.io/pip/3.8/get-pip.py
ARG PYTHON_PIP_VERSION=25.0.1

COPY requirements.txt /root/
COPY src/ /usr/local/bin/

RUN apk add --no-cache --update \
     curl openssl python3 python3-dev py3-configobj && \
    mkdir build && cd build && \
    wget -q -O get-pip.py $GETPIP_URI && \
    echo "$GETPIP_SHA  get-pip.py" | sha256sum -c && \
    python3 get-pip.py --no-cache-dir pip==$PYTHON_PIP_VERSION \
      --break-system-packages && \
    apk add --no-cache --virtual .fetch-deps \
      gcc git freetype-dev jpeg-dev musl-dev zlib-dev && \
    pip install -r /root/requirements.txt --break-system-packages && \
    chmod -R g+rx,o+rx /usr/local/bin && \
    adduser -S -u 2026 -g "Spamassassin" -s /bin/sh spamfilter && \
    addgroup spamfilter postdrop && \
    apk del .fetch-deps && \
    rm -fr /var/log/* /var/cache/apk/* /build && \
    find /usr/local -depth \( \
        \( -type d -a -name test -o -name tests \) -o \
        \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
      \) -exec rm -rf '{}' +;
