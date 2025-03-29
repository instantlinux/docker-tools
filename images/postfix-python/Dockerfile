ARG POSTFIX_VERSION=3.9.3-r0

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
ARG GETPIP_SHA=5b9e2f9bb476ce76f84942bb7247dec8d6c0bb9dbc8c62ba2543b81fd7a4243c
ARG GETPIP_URI=https://bootstrap.pypa.io/pip/3.7/get-pip.py
ARG PYTHON_PIP_VERSION=24.0

COPY requirements.txt /root/
COPY src/ /usr/local/bin/

RUN apk add --no-cache --update \
     curl openssl python3 python3-dev py3-configobj && \
    mkdir build && cd build && \
    wget -q -O get-pip.py $GETPIP_URI && \
    echo "$GETPIP_SHA  get-pip.py" | sha256sum -c && \
    python3 get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION --break-system-packages && \
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
