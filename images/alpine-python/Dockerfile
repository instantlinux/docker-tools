FROM alpine:3.7
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=alpine-python \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG PYTHON_PIP_VERSION=9.0.1
COPY requirements/ /root/
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
