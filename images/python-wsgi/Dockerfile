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

COPY requirements.txt uwsgi.ini /usr/src/
RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >>/etc/apk/repositories && \
    echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --virtual .fetch-deps gcc jpeg-dev libffi-dev musl-dev \
      libwebp-dev openssl-dev zlib-dev && \
    pip3 install cffi==$VERSION_CFFI && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libspatialite@testing \
      libwebp proj@community uwsgi zlib && \
    pip3 install -r /usr/src/requirements.txt && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
