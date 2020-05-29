FROM python:3.7.6-alpine3.11

MAINTAINER Rich Braun "richb@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
ARG TAG
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=python-wsgi \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/python-wsgi
ENV PYTHONPATH=/usr/local/lib/python3.7/site-packages
ARG VERSION_CFFI=1.14.0
ARG VERSION_UWSGI=2.0.18

COPY requirements.txt uwsgi.ini /usr/src/
RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >>/etc/apk/repositories && \
    echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --virtual .fetch-deps gcc git jpeg-dev libffi-dev make musl-dev \
      libwebp-dev openssl-dev pcre-dev zlib-dev && \
    pip3 install cffi==$VERSION_CFFI && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libwebp \
      proj@community uwsgi zlib && \
    cd /tmp && git clone --depth=1 --branch=$VERSION_UWSGI \
      https://github.com/unbit/uwsgi.git && cd uwsgi && \
    make plugin.python && mkdir -m 755 /usr/lib/uwsgi && \
    cp python_plugin.so /usr/lib/uwsgi/python3_plugin.so && \
    pip3 install -r /usr/src/requirements.txt && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache /tmp/uwsgi

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
