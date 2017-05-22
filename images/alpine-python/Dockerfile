FROM alpine:3.5
MAINTAINER Rich Braun "richb@instantlinux.net"

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
    rm -fr /var/log/* /var/cache/apk/* /build
