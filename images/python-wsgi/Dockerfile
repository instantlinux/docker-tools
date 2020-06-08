FROM python:3.8.3-alpine3.12

MAINTAINER Rich Braun "richb@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
ARG TAG
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=python-wsgi \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/python-wsgi
ENV PYTHONPATH=/usr/lib/python3.8/site-packages
ARG CFFI_VERSION=1.14.0-r2
ARG PYCRYPTOGRAPHY_VERSION=2.9.2-r0
ARG PYPILLOW_VERSION=7.1.2-r0
ARG UWSGI_VERSION=2.0.18-r8

COPY requirements.txt uwsgi.ini /usr/src/
RUN echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' \
      >>/etc/apk/repositories && \
    apk add --virtual .fetch-deps gcc git jpeg-dev libffi-dev make musl-dev \
      libwebp-dev openssl-dev pcre-dev zlib-dev && \
    apk add --update --no-cache geos jpeg libjpeg-turbo libwebp \
      proj@community py3-boto3 py3-botocore py3-cffi==$CFFI_VERSION \
      py3-coverage py3-cryptography==$PYCRYPTOGRAPHY_VERSION py3-flask \
      py3-itsdangerous py3-jsonschema py3-jwt \
      py3-pillow==$PYPILLOW_VERSION py3-requests py3-setuptools \
      py3-sqlalchemy py3-urllib3 py3-virtualenv uwsgi==$UWSGI_VERSION \
      uwsgi-python3 zlib && \
    pip3 install -r /usr/src/requirements.txt && pip freeze && \
    apk del .fetch-deps && rm -r /var/cache/apk/* /root/.cache

CMD ["uwsgi", "--ini", "/usr/src/uwsgi.ini"]
